module Git

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

    def self.add(path)
        `git add #{path}`
    end

    def self.commit(message)
        `git commit -m "#{message}" --quiet`
    end

end