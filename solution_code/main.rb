require_relative 'data_loader'
require_relative 'constraints'
require_relative 'router'
require_relative 'reporter'

# Умный поиск папки data (ищет рядом со скриптом или на уровень выше)
base_dir = Dir.exist?(File.join(__dir__, 'data')) ? __dir__ : File.expand_path('..', __dir__)

# 1. Инициализация данных
providers = DataLoader.load_providers(base_dir)
queue_data = DataLoader.load_queue(base_dir)

# 2. Основной процесс роутинга
routing_output = Router.process(queue_data, providers)

# 3. Формирование аналитики
report_data = Reporter.generate(
  providers, 
  routing_output[:stats], 
  routing_output[:total_processed], 
  queue_data.size
)

# 4. Выгрузка результатов в корень
DataLoader.save_json(File.join(base_dir, 'routing_decisions_test.json'), routing_output[:results])
DataLoader.save_json(File.join(base_dir, 'routing_decisions.json'), routing_output[:results])
DataLoader.save_json(File.join(base_dir, 'routing_report_test.json'), report_data)
DataLoader.save_json(File.join(base_dir, 'routing_report.json'), report_data)

puts "Успешно"
puts "- Обработано заявок: #{queue_data.size}"
puts "- Файлы решений и отчета обновлены."