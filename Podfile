platform :ios, '14.0'

ENV['COCOAPODS_DISABLE_STATS'] = 'true'

project 'Runner', {
  'Debug' => :debug,
  'Profile' => :release,
  'Release' => :release,
}

def flutter_root
  generated_xcode_build_settings_path = File.expand_path(File.join('..', 'Flutter', 'Generated.xcconfig'), __dir__)
  unless File.exist?(generated_xcode_build_settings_path)
    raise "#{generated_xcode_build_settings_path} must exist. If you're running pod install manually, make sure flutter pub get is executed first"
  end

  File.foreach(generated_xcode_build_settings_path) do |line|
    matches = line.match(/FLUTTER_ROOT\=(.*)/)
    return matches[1].strip if matches
  end
  raise "FLUTTER_ROOT not found in #{generated_xcode_build_settings_path}. Try deleting Generated.xcconfig, then run flutter pub get"
end

require File.expand_path(File.join('packages', 'flutter_tools', 'bin', 'podhelper'), flutter_root)

target 'Runner' do
  use_frameworks! :linkage => :static
  use_modular_headers!

  # ✅ Force compatible SDWebImage version
  pod 'SDWebImage', '5.19.7'

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))

  target 'RunnerTests' do
    inherit! :search_paths
  end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
  end

  # ✅ កែ BoringSSL-GRPC ដោយផ្ទាល់
  system("find Pods -name '*.xcconfig' -exec sed -i '' 's/-G//g' {} \\;")
  system("find Pods -name '*.podspec' -exec sed -i '' 's/-G//g' {} \\;")

  # ✅ Patch SDWebImage
  sd_metadata_path = File.join(Dir.pwd, 'Pods/SDWebImage/SDWebImage/Core/UIImage+Metadata.m')
  if File.exist?(sd_metadata_path)
    content = File.read(sd_metadata_path)
    if content.include?('isHighDynamicRange')
      content.gsub!('isHighDynamicRange', 'sd_isHighDynamicRange')
      File.write(sd_metadata_path, content)
      puts "✅ Patched SDWebImage!"
    end
  end
end