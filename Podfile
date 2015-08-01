# Uncomment this line to define a global platform for your project
platform :ios, '8.0'


target 'wishbox' do

source 'https://github.com/CocoaPods/Specs.git'

pod 'Facebook-iOS-SDK', '~> 3.23'
pod 'RestKit'
pod 'Masonry'
pod 'UICKeyChainStore'
pod 'SDWebImage'
pod 'GoogleAnalytics-iOS-SDK'
pod 'SVProgressHUD'
pod 'Instabug'

end


target 'wishboxTests' do

end


target 'add action' do

source 'https://github.com/CocoaPods/Specs.git'

pod 'UICKeyChainStore'
pod 'AFNetworking', '~> 1.3.0'

# Fix broken copy-resources phase per https://github.com/CocoaPods/CocoaPods/issues/1546.
post_install do |installer|
    installer.project.targets.each do |target|
        scriptBaseName = "\"Pods/Target Support Files/#{target.name}/#{target.name}-resources\""
        sh = (<<-EOT)
        if [ -f #{scriptBaseName}.sh ]; then
            if [ ! -f #{scriptBaseName}.sh.bak ]; then
                cp #{scriptBaseName}.sh #{scriptBaseName}.sh.bak;
            fi;
            sed '/WRAPPER_EXTENSION/,/fi\\n/d' #{scriptBaseName}.sh > #{scriptBaseName}.sh.temp;
            sed '/*.xcassets)/,/;;/d' #{scriptBaseName}.sh.temp > #{scriptBaseName}.sh;
            rm #{scriptBaseName}.sh.temp;
        fi;
        EOT
    `#{sh}`
    end
end

end

