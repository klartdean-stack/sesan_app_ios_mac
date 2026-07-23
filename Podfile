post_install do |installer|

installer.pods_project.targets.each do |target|

```
flutter_additional_ios_build_settings(target)

target.build_configurations.each do |config|
  # Force all Pods to iOS 14.0
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
end

# Fix BoringSSL-GRPC for Xcode 16
if target.name.include?('BoringSSL-GRPC')

  target.source_build_phase.files.each do |build_file|
    next unless build_file.settings

    compiler_flags = build_file.settings['COMPILER_FLAGS']
    next unless compiler_flags

    # Remove the invalid GCC warning flag
    compiler_flags = compiler_flags.gsub(
      '-GCC_WARN_INHIBIT_ALL_WARNINGS',
      ''
    )

    build_file.settings['COMPILER_FLAGS'] = compiler_flags

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

```
content = File.read(sd_metadata_path)

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
