require 'json'

module DataLoader
  def self.load_providers(base_dir)
    path = File.join(base_dir, 'data', 'providers.json')
    JSON.parse(File.read(path))['providers']
  end

  def self.load_queue(base_dir)
    queue_file = [
      File.join(base_dir, 'data', 'operations_queue_test.json'),
      File.join(base_dir, 'data', 'operations_queue_10.json'),
      File.join(base_dir, 'data', 'operations_queue.json')
    ].find { |path| File.exist?(path) }

    unless queue_file
      puts "Ошибка: не найден файл очереди в папке data/"
      exit 1
    end
    JSON.parse(File.read(queue_file))
  end

  def self.save_json(path, data)
    File.write(path, JSON.pretty_generate(data))
  end
end