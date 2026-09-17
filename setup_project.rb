require "xcodeproj"

project_path = File.join(__dir__, "MashreqApp.xcodeproj")
project = Xcodeproj::Project.new(project_path)
target = project.new_target(:application, "MashreqApp", :ios, "17.0")

main_group = project.main_group.new_group("MashreqApp", "MashreqApp")

Dir.glob(File.join(__dir__, "MashreqApp", "**", "*.swift")).sort.each do |absolute_path|
  relative_path = absolute_path.delete_prefix(File.join(__dir__, "MashreqApp") + "/")
  file_reference = main_group.new_file(relative_path)
  target.source_build_phase.add_file_reference(file_reference)
end

assets = main_group.new_file("Assets.xcassets")
target.resources_build_phase.add_file_reference(assets)

# Подключаем все начертания 29LT Bukra как ресурсы приложения.
Dir.glob(File.join(__dir__, "MashreqApp", "Fonts", "*.ttf")).sort.each do |absolute_path|
  relative_path = absolute_path.delete_prefix(File.join(__dir__, "MashreqApp") + "/")
  font_reference = main_group.new_file(relative_path)
  target.resources_build_phase.add_file_reference(font_reference)
end

target.build_configurations.each do |config|
  settings = config.build_settings
  settings["PRODUCT_BUNDLE_IDENTIFIER"] = "com.madina.mashreqdemo"
  settings["PRODUCT_NAME"] = "$(TARGET_NAME)"
  settings["SWIFT_VERSION"] = "6.0"
  settings["IPHONEOS_DEPLOYMENT_TARGET"] = "17.0"
  settings["TARGETED_DEVICE_FAMILY"] = "1"
  settings["GENERATE_INFOPLIST_FILE"] = "NO"
  settings["INFOPLIST_FILE"] = "MashreqApp/Info.plist"
  settings["ASSETCATALOG_COMPILER_APPICON_NAME"] = "AppIcon"
  settings["CODE_SIGN_STYLE"] = "Automatic"
  settings["DEVELOPMENT_TEAM"] = ""
  settings["ENABLE_PREVIEWS"] = "YES"
end

project.save
puts "Created #{project_path}"
