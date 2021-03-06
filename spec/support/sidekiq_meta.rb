RSpec.configure do |config|
  VERSION_REGEX = /(?<operator>[<>=]+)?\s?(?<version>(\d+.?)+)/m
  config.before(:each) do |example|
    Sidekiq.redis(&:flushdb)
    Sidekiq::Worker.clear_all
    if (sidekiq = example.metadata[:sidekiq])
      sidekiq = :fake if sidekiq == true
      Sidekiq::Testing.send("#{sidekiq}!")
    end

    sidekiq_ver = example.metadata[:sidekiq_ver]
    version, operator = VERSION_REGEX.match(sidekiq_ver.to_s) do |m|
      raise 'Please specify how to compare the version with >= or < or =' unless m[:operator]
      [m[:version], m[:operator]]
    end

    if version && operator && Sidekiq::VERSION.send(operator, version).nil?
      skip('Skipped due to version check (requirement was that sidekiq version is ' \
           "#{operator} #{version}; was #{Sidekiq::VERSION})")
    end
  end

  config.after(:each) do |example|
    Sidekiq::Testing.disable! unless example.metadata[:sidekiq].nil?
  end
end
