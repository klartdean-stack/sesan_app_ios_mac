platform :ios, '14.0'

ENV['COCOAPODS_DISABLE_STATS'] = 'true'

project 'Runner', {
'Debug' => :debug,
'Profile' => :release,
'Release' => :release,
}

def flutter_root
generated_xcode_build_settings_path = File.expand_path(
File.join('..', 'Flutter', 'Generated.xcconfig'),
**dir**
)

unless File.exist?(generated_xcode_build_settings_path)
raise "#{generated_xcode_build_settings_path} must exist. If you're running pod install manually, make sure flutter pub get is executed first"
end

File.foreach(generated_xcode_build_settings_path) do |line|
matches = line.match(/FLUTTER_ROOT=(.*)/)
return matches[1].strip if matches
end

raise "FLUTTER_ROOT not found in #{generated_xcode_build_settings_path}. Try deleting Generated.xcconfig, then run flutter pub get"
end

require File.expand_path(
File.join('packages', 'flutter_tools', 'bin', 'podhelper'),
flutter_root
)

target 'Runner' do
use_frameworks! :linkage => :static
use_modular_headers!

# Compatible SDWebImage version

pod 'SDWebImage', '5.19.7'

flutter_install_all_ios_pods File.dirname(File.realpath(**FILE**))

target 'RunnerTests' do
inherit! :search_paths
end
end
post_install do |installer|

installer.pods_project.targets.each do |target|

```
flutter_additional_ios_build_settings(target)

target.build_configurations.each do |config|
  # Force all Pods to iOS 14.0
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'

  # Remove standalone "-G" only from build settings
  %w[
    OTHER_CFLAGS
    OTHER_CPLUSPLUSFLAGS
    OTHER_LDFLAGS
  ].each do |key|

    value = config.build_settings[key]

    if value.is_a?(Array)
      config.build_settings[key] = value.reject do |flag|
        flag.to_s == '-G'
      end
    elsif value.is_a?(String)
      config.build_settings[key] = value
        .split
        .reject { |flag| flag == '-G' }
        .join(' ')
    end
  end
end

# Fix BoringSSL-GRPC per-file compiler flags
if target.name.start_with?('BoringSSL-GRPC')
  target.source_build_phase.files.each do |build_file|
    next unless build_file.settings

    flags = build_file.settings['COMPILER_FLAGS']
    next unless flags

    if flags.is_a?(String)
      flags = flags.split
    end

    # Remove only the invalid standalone -G flag
    flags = flags.reject { |flag| flag == '-G' }

    build_file.settings['COMPILER_FLAGS'] = flags.join(' ')
  end

  puts "✅ Fixed BoringSSL-GRPC compiler flags"
end
```

end

# Patch SDWebImage

sd_metadata_path = File.join(
Dir.pwd,
'Pods/SDWebImage/SDWebImage/Core/UIImage+Metadata.m'
)

if File.exist?(sd_metadata_path)
content = File.read(sd_metadata_path)

```
if content.include?('isHighDynamicRange')
  content.gsub!(
    'isHighDynamicRange',
    'sd_isHighDynamicRange'
  )

  File.write(
    sd_metadata_path,
    content
  )

  puts "✅ Patched SDWebImage!"
end
```

end

end
