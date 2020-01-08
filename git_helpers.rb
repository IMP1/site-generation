module Git

    def self.branch?(branch)
        branches = run("git branch", false)
        regex = Regexp.new('[\\n\\s\\*]+' + Regexp.escape(branch.to_s) + '\\n')
        result = ((branches =~ regex) ? true : false)
        return result
    end

    def self.current_branch
        branch = `git branch`
        current_branch = branch.match(/\* (\w+)/)[1]
    end

    def self.checkout(branch, &block)
        if block.nil?
            return `git checkout #{branch} --quiet`
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