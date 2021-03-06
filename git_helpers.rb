module Git

    def self.any_unstaged?(repo_dir=nil)
        if repo_dir
            Dir.chdir(repo_dir) do
                return any_unstaged?
            end
        end
        changes = `git diff-index HEAD`
        return !changes.empty?
    end

    def self.branch?(branch, repo_dir=nil)
        if repo_dir
            Dir.chdir(repo_dir) do
                return branch?(branch)
            end
        end
        branches = `git branch`
        regex = Regexp.new('[\\n\\s\\*]+' + Regexp.escape(branch.to_s) + '\\n')
        result = ((branches =~ regex) ? true : false)
        return result
    end

    def self.current_branch(repo_dir=nil)
        if repo_dir
            Dir.chdir(repo_dir) do
                return current_branch(branch)
            end
        end
        branches = `git branch`
        current_branch = branches.match(/\* (\w+)/)[1]
    end

    def self.checkout(branch, file=nil, &block)
        if block.nil?
            return `git checkout #{branch} #{file || ""} --quiet`
        end
        previous_branch = current_branch
        checkout(branch)
        block.call
        checkout(previous_branch)
    end

    def self.current_index
        return `git rev-parse HEAD`
    end

    def self.changed_files(last_index)
        return `git diff #{last_index} --name-only`.lines.select { |line| !line.chomp.empty? }.map { |line| line.chomp }
    end

    def self.add(path)
        `git add #{path}`
    end

    def self.commit(*messages)
        msg = messages.map { |msg| "-m \"#{msg}\"" }.join(" ")
        `git commit #{msg} --quiet`
    end

end