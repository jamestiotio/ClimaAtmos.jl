#! /bin/bash
set -euo pipefail

low_res_process_counts=(1 2 4 8 16 32)
mid_res_process_counts=(1 2 4 8 16 32 64)
high_res_process_counts=(1 2 4 8 16 32 64 128)
FT="Float32"
resolutions=("low" "mid" "high")
max_procs_per_node=16 # limit this artificially for profiling
profiling=enable
exclusive=true
mpi_impl="openmpi"

# set up environment and agents
cat << EOM
env:
  JULIA_VERSION: "1.8.1"
  MPICH_VERSION: "4.0.0"
  OPENMPI_VERSION: "4.1.1"
  MPI_IMPL: "$mpi_impl"
  CUDA_VERSION: "11.3"
  OPENBLAS_NUM_THREADS: 1
  CLIMATEMACHINE_SETTINGS_FIX_RNG_SEED: "true"

agents:
  config: cpu
  queue: central

steps:
  - label: "init :computer:"
    key: "init_cpu_env"
    command:
      - "julia --project=examples -e 'using Pkg; Pkg.instantiate(;verbose=true)'"
      - "julia --project=examples -e 'using Pkg; Pkg.precompile()'"
      - "julia --project=examples -e 'using Pkg; Pkg.status()'"

    agents:
      slurm_cpus_per_task: 8
    env:
      JULIA_NUM_PRECOMPILE_TASKS: 8

  - wait

EOM

for res in ${resolutions[@]}; do

cat << EOM
  - group: "ClimaAtmos $res-resolution scaling tests"
    steps:

EOM


if [[ "$res" == "low" ]]; then
    process_counts=${low_res_process_counts[@]}
elif [[ "$res" == "mid" ]]; then
    process_counts=${mid_res_process_counts[@]}
else
    process_counts=${high_res_process_counts[@]}
fi

for nprocs in ${process_counts[@]}; do

    job_id="sphere_held_suarez_${res}_res_rhoe_$nprocs"

if [[ "$res" == "low" ]]; then
    command="julia --color=yes --project=examples examples/hybrid/driver.jl --job_id $job_id --forcing held_suarez --enable_threading false --FLOAT_TYPE $FT --tracer_upwinding none --t_end 10days --dt 400secs --z_elem 10 --h_elem 6 --kappa_4 2e17"
elif [[ "$res" == "mid" ]]; then
    command="julia --color=yes --project=examples examples/hybrid/driver.jl --job_id $job_id --forcing held_suarez --enable_threading false --FLOAT_TYPE $FT --tracer_upwinding none --t_end 4days --dt 150secs --z_elem 45 --dz_bottom 30 --h_elem 16 --kappa_4 1e16"
else
    command="julia --color=yes --project=examples examples/hybrid/driver.jl --job_id $job_id --forcing held_suarez --enable_threading false --FLOAT_TYPE $FT --tracer_upwinding none --t_end 1days --dt 50secs --z_elem 45 --h_elem 30 --kappa_4 5e14"
fi

if [[ "$mpi_impl" == "mpich" ]]; then
    rank_env_var="PMI_RANK"
else
    rank_env_var="OMPI_COMM_WORLD_RANK"
fi
if [[ "$profiling" == "enable" ]]; then
    command="nsys profile --sample=none --trace=nvtx,mpi --mpi-impl=$mpi_impl --output=${job_id}/rank-%q{$rank_env_var} $command"
    cpus_per_proc=2
else
    cpus_per_proc=1
fi
if [[ "$mpi_impl" == "mpich" ]]; then
    launcher="srun --cpu-bind=cores"
else
    launcher="mpiexec --map-by node:PE=$cpus_per_proc --bind-to core"
fi

if [[ $nprocs -gt 4 ]]; then
    time="01:00:00"
else
    time="04:00:00"
fi


cat << EOM
    - label: "$nprocs"
      key: "$job_id"
      command:
        - "module load cuda/11.3 nsight-systems/2022.2.1"
        - "$launcher $command"
        - "find ${job_id} -iname '*.nsys-rep' -printf '%f\\\\n' | sort -V | jq --raw-input --slurp 'split(\"\n\") | .[0:-1] | {files: .} + {\"extension\": \"nsys-view\", \"version\": \"1.0\"}' > ${job_id}/${job_id}.nsys-view"
        - "find ${job_id} -iname '*.nsys-*' | sort -V | tar cvzf ${job_id}-nsys.tar.gz -T -"
      artifact_paths:
        - "${job_id}/scaling_data_${nprocs}_processes.jld2"
        - "${job_id}-nsys.tar.gz"
      env:
        CLIMACORE_DISTRIBUTED: "MPI"
      agents:
        config: cpu
        queue: central
        slurm_time: $time
EOM

if [[ "$exclusive" == "true" ]]; then

    nnodes=$(( (nprocs+max_procs_per_node-1) /max_procs_per_node )) # ceiling divide
    procs_per_node=$(( nprocs/nnodes ))

    cat << EOM
        slurm_nodes: $nnodes
        slurm_tasks_per_node: $procs_per_node
        slurm_cpus_per_task: $cpus_per_proc
        slurm_mem: 0
        slurm_exclusive:
EOM
else
    cat << EOM
        slurm_ntasks: $nprocs
        slurm_cpus_per_task: $cpus_per_proc
        slurm_mem_per_cpu: 8G
EOM
fi

done

cat << EOM
    - wait

    - label: ":chart_with_upwards_trend:"
      key: "cpu_scaling_plots_$res-resolution"
      command:
        - "julia --color=yes --project=examples examples/hybrid/plot_scaling_results.jl --job_id sphere_held_suarez_${res}_res_rhoe"
      artifact_paths:
        - "${res}-resolution_*.png"
        - "${res}-resolution_*.pdf"
      agents:
        config: cpu
        queue: central
        slurm_nodes: 1
        slurm_tasks_per_node: 1

EOM
done