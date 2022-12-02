#
# Be sure to run `pod lib lint SectionedTable.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'SectionedTable'
  s.version          = '2.1.1'
  s.summary          = 'Sections for UITableView'

  s.description      = <<-DESC
  Sections for UITableView.
                       DESC

  s.homepage         = 'https://git.dktsoft.com:2008/sapo-mobile/sectioned-table'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'kientux' => 'ntkien93@gmail.com' }
  s.source           = { :git => 'https://git.dktsoft.com:2008/sapo-mobile/sectioned-table.git', :tag => s.version.to_s }

  s.ios.deployment_target = '10.0'
  s.swift_versions = '5.5'

  s.source_files = 'Sources/SectionedTable/**/*.swift'
end
