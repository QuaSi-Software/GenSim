
def run_os_worflow(os_bin_path, output_folder, workflow_file_name)
    arguments = [
        os_bin_path + "/OpenStudio.exe",
        "--verbose", "run", "--workflow",
        output_folder + "/" + workflow_file_name
    ]
    system(arguments.join(" "))
end

if $0 == __FILE__
    if ARGV.length >= 3
        run_os_worflow(ARGV[0], ARGV[1], ARGV[2])
    else
        print("Needs three arguments.")
    end
end