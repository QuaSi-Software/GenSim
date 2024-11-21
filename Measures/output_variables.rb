require 'json'

def get_output_variables(output_level="Normal")
    path = File.join(File.dirname(__FILE__), 'output_variables.json')
    file_content = File.read(path)
    variable_definitions = JSON.parse(file_content)
    filtered = []
    variable_definitions.each do |var_def|
        if !var_def["output_levels"].include?(output_level)
            next
        end
        filtered << var_def
    end
    return filtered
end