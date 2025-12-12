#!/usr/bin/env python3

import os
import shutil
import re
import sys
from subprocess import check_output, CalledProcessError
import subprocess
import colorama
from colorama import Fore, Style

def verilator_compile_and_run(tb_file, project_dir, build_dir):

    base = os.path.splitext(tb_file)[0]
    mdir = os.path.join(build_dir, base)
    os.makedirs(mdir, exist_ok=True)

    cmd = [
        "verilator",
        "--binary",
        "-Wall",
        "-Wno-fatal",
        "--top-module", base,
        "--Mdir", mdir,
        tb_file,
    ]

    cmd_str = " ".join(cmd)
    print(cmd_str)

    try:
        output = check_output(cmd, cwd=project_dir, stderr=subprocess.STDOUT).decode("utf-8")
        print(output)
    except CalledProcessError as e:
        print(Fore.YELLOW + f"Error while compiling {tb_file}\nError code: {e.returncode}\n")
        try:
            print(e.output.decode("utf-8"))
        except Exception:
            pass
        print(Style.RESET_ALL)
        return {"assertion_errors": 0, "run_errors": 1}

    binary_path = os.path.join(mdir, "V" + base)
    print(f"Running {binary_path}")

    try:
        sim_out = check_output([binary_path], cwd=project_dir, stderr=subprocess.STDOUT).decode("utf-8")
        print(sim_out)
        assertion_errors = len(re.findall(r'(Error: |ERROR: )', sim_out))
        color = Fore.YELLOW if assertion_errors > 0 else Fore.GREEN
        print(color + f"Found {assertion_errors} assertion errors in {tb_file}" + Style.RESET_ALL + "\n")
        return {"assertion_errors": assertion_errors, "run_errors": 0}
    except CalledProcessError as e:
        print(Fore.YELLOW + f"Error while running {tb_file}\nError code: {e.returncode}\n")
        try:
            print(e.output.decode("utf-8"))
        except Exception:
            pass
        print(Style.RESET_ALL)
        return {"assertion_errors": 0, "run_errors": 1}



def summarise_results(results):
    (
        assertion_errors,
        run_errors,
        successful_test_benches,
        unsuccessful_test_benches,
        test_benches_with_assertion_errors
    ) = results

    color = Fore.YELLOW if unsuccessful_test_benches > 0 else Fore.GREEN
    print(color + "\nFinished testing:\n")
    total_tests = successful_test_benches + unsuccessful_test_benches
    print(Fore.BLUE + f"From a total of {total_tests} test benches.\n")
    print(Fore.GREEN + f"{successful_test_benches} test benches ran without any runtime errors\n")

    if unsuccessful_test_benches > 0:
        print(
            Fore.YELLOW
            + f"{unsuccessful_test_benches} test benches had errors, of which:"
            + f"\n{test_benches_with_assertion_errors} ran, but had a total of "
            + f"{assertion_errors} assertion errors"
        )
    else:
        print(Fore.GREEN + "All tests succeeded!")

    if run_errors > 0:
        print(Fore.YELLOW + f"{run_errors} test benches failed to run" + Style.RESET_ALL)
    else:
        print(Style.RESET_ALL)


def compile_and_run_simulations(project):
    build_dir_root = os.path.join(dir_path, "build")
    if os.path.exists(build_dir_root):
        shutil.rmtree(build_dir_root)
    os.mkdir(build_dir_root)

    project_dir = os.path.join(dir_path, f"0{project}")

    # Determine which testbenches to run
    if len(sys.argv) > 2:
        # User-specified single file (e.g. "cpu_tb.sv" or "cpu.sv")
        tb_files = [sys.argv[2]]
    else:
        # Default: all *_tb.sv files in the project dir
        tb_files = [f for f in os.listdir(project_dir) if re.search(r'.*_tb\.sv$', f)]
        if not tb_files:
            # Fallback: no *_tb.sv, run all .sv files as tops
            tb_files = [f for f in os.listdir(project_dir) if re.search(r'.*\.sv$', f)]

    print(f"\nStarting compilation and simulation of project 0{project} with Verilator...")
    print(f"Testbenches: {tb_files}\n")

    assertion_errors = 0
    run_errors = 0
    successful_test_benches = 0
    unsuccessful_test_benches = 0
    test_benches_with_assertion_errors = 0

    # Run each testbench sequentially
    for tb in tb_files:
        res = verilator_compile_and_run(tb, project_dir, build_dir_root)
        assertion_errors += res["assertion_errors"]
        run_errors += res["run_errors"]

        if res["assertion_errors"] > 0:
            test_benches_with_assertion_errors += 1

        if res["run_errors"] > 0 or res["assertion_errors"] > 0:
            unsuccessful_test_benches += 1
        else:
            successful_test_benches += 1

    summarise_results([
        assertion_errors,
        run_errors,
        successful_test_benches,
        unsuccessful_test_benches,
        test_benches_with_assertion_errors
    ])

    shutil.rmtree(build_dir_root)


if __name__ == '__main__':

    colorama.init(autoreset=True)
    dir_path = os.path.dirname(os.path.realpath(__file__))

    if len(sys.argv) < 2:
        print("Usage: python3 test.py <project_number> [testbench_file]")
        sys.exit(1)

    try:
        project = int(sys.argv[1])
    except ValueError:
        print("Project number must be an integer.")
        sys.exit(1)

    compile_and_run_simulations(project)
