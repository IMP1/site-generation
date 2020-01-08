require "ostruct"
require "exit_code"


class ArgParse

    @@options = []
    @@flags = []
    @@positionals = []

    def self.option(name, required, commands, allow_multiple, value_options=nil, &validation)
        if @@options.any? { |opt| opt.name == name } or 
            @@flags.any? { |opt| opt.name == name } or 
            @@positionals.any? { |opt| opt.name == name }
            raise "Name clash"
        end
        @@options.push(Option.new(name, required, commands, allow_multiple, value_options, &validation))
    end

    def self.flag(name, commands)
        # @@flags.push(Flag.new(name, commands))
    end

    def self.positional(name, required, &validation)
        # @@positionals.push(Positional.new(name, required, &validation))
    end

    def self.parse
        exit_on_unrecognised = false # TODO: get this from user somehow

        values = OpenStruct.new
        @@options.each do |option|
            if not option.allow_multiple and ARGV.count { |arg| option.commands.include?(arg) } > 1
                puts "Multiple #{option.name.to_s} arguments were included (#{option.commands.join(" and/or ")}). Exiting."
                exit(ExitCode::USAGE)
            end
            arg_index = ARGV.index { |arg| option.commands.include?(arg) }
            if arg_index
                ARGV.delete_at(arg_index)
                option.value = ARGV.delete_at(arg_index)
                error = option.check_for_error
                if error then
                    exit(error)
                else
                    values[option.name] = option.value
                end
            elsif option.required
                puts "A #{option.name.to_s} argument must be provided."
                exit(ExitCode::USAGE)
            end
        end

        @@flags.each do |flag|
            if ARGV.count { |arg| flag.commands.include?(arg) } > 1
                puts "Multiple #{flag.name.to_s} flags were included (#{flag.commands.join(" and/or ")}). Exiting."
                exit(ExitCode::USAGE)
            end
            arg_index = ARGV.index { |arg| flag.commands.include?(arg) }
            if arg_index
                ARGV.delete_at(arg_index)
                values[flag.name] = true
            end
        end

        # Any Other Arguments
        valid = true
        ARGV.select { |arg| arg[0] == "-" }.each do |a|
            puts "Unrecognised option '#{arg}'."
            valid = false
        end
        exit(ExitCode::USAGE) if !valid and exit_on_unrecognised 

        # TODO: handle remaining args as positionals

# # Programme Filename
# if ARGV.size > 0
#     programme_filename = ARGV.delete_at(0)
# else
#     programme_filename = gets.chomp
# end
# if !File.exists?(programme_filename)
#     puts "Could not find programme file '#{programme_filename}'. Exiting."
#     exit(ExitCode::NOINPUT)
# end
# begin
#     programme_file = File.open(programme_filename, 'r')
#     programme_source = programme_file.read
# rescue SystemCallError => e
#     p e
#     puts e.class
    
#     # TODO: [0.6.0] handle system errors and return appropriate exit codes.
#     # http://blog.honeybadger.io/understanding-rubys-strange-errno-exceptions/

#     puts "You don't have sufficient permissions to access the programme file."
#     exit(ExitCode::NOPERM)
# end

        return values
    end

end

class Option
    attr_reader :name
    attr_reader :commands
    attr_reader :required
    attr_reader :allow_multiple
    attr_reader :value_set

    def initialize(name, required, commands, allow_multiple, value_options=nil, &validation)
        @name = name
        @commands = commands
        @required = required
        @allow_multiple = allow_multiple
        @value_options = value_options
        @value = nil
        @value_set = false
        @validation = validation
    end

    def value=(value)
        @value = value
        @value_set = true
    end

    def check_for_error
        return ExitCode::USAGE if @required and not @value_set
        return ExitCode::USAGE unless @value_options.nil? or @value_options.include?(@value)
        return @validation.call(@value)
    end

end

option = Option.new(:source_branch, false, ["--source-branch"], false) do |value|
    if value.nil?
        puts "A filepath must be supplied as an input file."
        return ExitCode::USAGE
    end
    if !File.exists?(value)
        puts "Could not find source branch '#{source_branch}'. Exiting."
        return ExitCode::NOINPUT
    end
    return nil
end