module PageServer

    @@dir = __dir__

    def self.set_dir(dir)
        @@dir = dir
    end

    def dir
        return @@dir
    end

end