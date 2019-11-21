class KeyGenerator
  def self.generate(filename)
    ctime = File.ctime(filename)
    basename = File.basename(filename)
    ctime.strftime("%Y/%m/%Y-%m-%d-#{basename}")
  end
end