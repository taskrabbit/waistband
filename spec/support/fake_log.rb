class FakeLog
  attr_reader :level

  def level=(val)
    @level = val
  end

  def info(val);  end
  def debug(val); end
  def fatal(val); end
  def warn(val); end
  def error(val);  end
end
