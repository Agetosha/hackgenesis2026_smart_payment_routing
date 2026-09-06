# Автоматически найдет самый свежий или самый крупный файл с очередью в папке data/
require 'json'

module DataLoader
  def self.load_providers(base_dir)
    path = File.join(base_dir, 'data', 'providers.json')
    JSON.parse(File.read(path))['providers']
  end

  def self.load_queue(base_dir)
    # Находим все файлы очереди в папке data/
    candidates = Dir.glob(File.join(base_dir, 'data', 'operations_queue*'))
    
    # Исключаем служебные/лишние, если есть
    candidates.reject! { |f| f.end_with?('.csv') }

    # Выбираем самый большой по размеру файл (в 90 заявках размер файла будет больше, чем в 10)
    queue_file = candidates.max_by { |path| File.size(path) }

    unless queue_file && File.exist?(queue_file)
      puts "Ошибка: не найден файл очереди в папке data/"
      exit 1
    end

    puts "Загружен файл очереди: #{queue_file}"
    JSON.parse(File.read(queue_file))
  end

  def self.save_json(path, data)
    File.write(path, JSON.pretty_generate(data))
  end
end