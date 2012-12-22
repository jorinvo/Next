task :default => :run


desc 'run Next.app'

task :run => :build do
	#close current process if exists
	sh 'killall Next &'
	sh 'open Next.app'
end


desc 'create Release/Next.dmg'

task :archive => :build do
	version = File.read('VERSION').to_f
	if File.exists? 'Release/Next.dmg'
		mv 'Release/Next.dmg', "Release/Next-#{version}.dmg"
	end
	version += 0.01
	File.write('VERSION', version.round(2))
	mkdir_p 'Release/tmp/Next'
	ln_s '/Applications', 'Release/tmp/Next/Applications'
	cp_r 'Next.app', 'Release/tmp/Next'
	#create Release/Next.dmg from Release/tmp/Next
	sh 'hdiutil create Release/tmp/Next.dmg -ov -volname "Next" -fs HFS+ -srcfolder "Release/tmp/Next/"'
	sh 'hdiutil convert Release/tmp/Next.dmg -format UDZO -o Release/Next.dmg'
	rm_rf 'Release/tmp'
end


desc 'create Next.app'

task :build do
	sh 'xcodebuild'
	rm_rf 'Next.app'
	mv 'build/Release/Next.app', '.'
	rm_rf 'build'
end