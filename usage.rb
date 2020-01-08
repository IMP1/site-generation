NAME = "Site Generator"

VERSION = "0.1.0"

USAGE = <<~END
Usage:
    
  generate {--help | --version}
    
  generate 

END

ARGUMENTS = <<~END

  help           : Prints this help message.
  version        : Prints the current version.

END

GITHUB_LINK = "https://github.com/IMP1/site-generation"

def handle_help_and_version
    if ARGV.include?("--help") || ARGV.include?("help")
        puts "#{NAME} v#{VERSION}"
        puts
        puts USAGE
        puts
        puts "Arguments:"
        puts
        puts ARGUMENTS
        puts
        puts "Report any problems, ask questions, or browse the source at #{GITHUB_LINK}"
        return ExitCode::OK
    end

    if ARGV.include?("-h")
        puts "#{NAME} v#{VERSION}"
        puts
        puts USAGE
        puts
        puts "Report any problems, ask questions, or browse the source at https://github.com/IMP1/blossom"
        return ExitCode::OK
    end

    if ARGV.include?("--version")
        puts "#{NAME} version #{VERSION}"
        return ExitCode::OK
    end
    
    return nil
end