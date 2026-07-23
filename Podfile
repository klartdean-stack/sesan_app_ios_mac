post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)

    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
    end
  end

  # ============================================================
  # PATCH SDWebImage UIImage+Metadata.m
  # ============================================================

  sd_metadata_path = File.join(
    installer.sandbox.root.to_s,
    'SDWebImage/SDWebImage/Core/UIImage+Metadata.m'
  )

  if File.exist?(sd_metadata_path)
    content = File.read(sd_metadata_path)

    old_code = 'return self.isHighDynamicRange;'
    new_code = 'return [SDImageCoderHelper CGImageIsHDR:self.CGImage];'

    if content.include?(old_code)
      content = content.gsub(old_code, new_code)
      File.write(sd_metadata_path, content)
      puts "✅ PATCHED UIImage+Metadata.m"
    else
      puts "ℹ️ UIImage+Metadata.m already patched"
    end
  else
    puts "❌ UIImage+Metadata.m NOT FOUND"
  end

  # ============================================================
  # PATCH SDImageIOAnimatedCoder.m
  # ============================================================

  sd_animated_path = File.join(
    installer.sandbox.root.to_s,
    'SDWebImage/SDWebImage/Core/SDImageIOAnimatedCoder.m'
  )

  if File.exist?(sd_animated_path)
    content = File.read(sd_animated_path)

    if content.include?('kCGImageSourceDecodeRequest')
      content = content.gsub(
        /.*kCGImageSourceDecodeRequest.*\n/,
        ''
      )

      File.write(sd_animated_path, content)
      puts "✅ PATCHED SDImageIOAnimatedCoder.m"
    else
      puts "ℹ️ SDImageIOAnimatedCoder.m already patched"
    end
  else
    puts "❌ SDImageIOAnimatedCoder.m NOT FOUND"
  end
end