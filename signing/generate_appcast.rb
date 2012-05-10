#!/usr/bin/env ruby -KU
# encoding: utf-8
#
# Code Author: David Jennes

require 'repository_downloads'
require 'sparkle_signature'
require 'date'
require 'plist'
require 'rexml/document'

module GitHubDeployment
    class AppcastGenerator
        SIGNATURE_FILE = 'dsa_priv.pem'
        APPCAST_TEMPLATE = 'appcast.xml'
        
        # attributes
        attr_accessor :file, :repo_user, :repo_name, :signature_file, :appcast_url
        
        # Constructor
        # file: The application file
        # username: The repository's username
        # repository: The repository's actual name
        # url: URL of where the appcast will be available
        def initialize(file, username, repository, url)
            # check if necessary files exist
            raise "#{file} does not exist!" if Dir[file].empty?
            raise "Unable to find #{SIGNATURE_FILE}!" if !File.exists?(SIGNATURE_FILE)
            
            # init variables
            @file = file
            @repo_user = username
            @repo_name = repository
            @appcast_url = url
            @appname = File.basename(file, '.app')
            @version = extractVersion(file)
            @signature_file = SIGNATURE_FILE
        end
        
        def generate(output)
            # generate archive
            file = archive_name()
            archive(file)
            
            # other data
            signature = SparkleSignature.calculate(file, SIGNATURE_FILE)
            size = File.size(file)
            
            downloads = RepositoryDownloads.new(@repo_user, @repo_name)
            url = downloads.create(file, file, 'description here!')
            
            # write to appcast xml
            xmldoc = genXML(signature, size, url)
            File.open(output, 'w') { |f| xmldoc.write(f) }
        end
        
        private
        
        # Extract the version information from an application
        # file: Path to application to get info from
        # returns: The extracted version string
        def extractVersion(file)
            plist_obj = Plist::parse_xml("#{file}/Contents/Info.plist")
            return plist_obj['CFBundleVersion']
        end
        
        # Generate the archive name based on the app's name and version
        # returns: The generated filename
        def archive_name()
            return "#{@appname} #{@version}.zip"
        end
        
        # Create a ZIP archive from the specified app file
        # output: desired archive name
        def archive(output)
            # remove old archives
            Dir["#{@appname} *.zip"].each { |old| File.delete(old) }
            
            # compress
            system("ditto -ck --keepParent '#{@file}' '#{output}'") 
        end
        
        # Based on given info, generate appcast XML document
        # returns: the XML document
        def genXML(signature, size, url)
            xmldoc = REXML::Document.new(File.read(APPCAST_TEMPLATE))
            pubdate = DateTime.now.strftime('%a, %d %b %G %T %z')
            
            REXML::XPath.first(xmldoc, '//channel/title').text = "#{@appname} Changelog"
            REXML::XPath.first(xmldoc, '//link').text = @appcast_url
            REXML::XPath.first(xmldoc, '//item/title').text = "Version #{@version}"
            REXML::XPath.first(xmldoc, '//item/pubDate').text = pubdate
            
            enclosure = REXML::XPath.first(xmldoc, '//item/enclosure')
            enclosure.attributes['sparkle:dsaSignature'] = signature
            enclosure.attributes['length'] = size
            enclosure.attributes['url'] = url
            enclosure.attributes['sparkle:version'] = @version
            
            return xmldoc
        end
    end
    
    class NightlyAppcastGenerator < AppcastGenerator
        # Extract the version information from an application
        # For nightlies, generate a version based on the date and time
        # file: Path to application to get info from
        # returns: The extracted version string
        def extractVersion(file)
            # version format: year month day hour minutes
            version = DateTime.now.strftime('%G%m%d%H%M')
            
            # change internal version of application
            plist_obj = Plist::parse_xml("#{file}/Contents/Info.plist")
            plist_obj['CFBundleVersion'] = version
            
            return version
        end
        
        # Generate the archive name based on the app's name and version
        # returns: The generated filename
        def archive_name()
            return "#{@appname} Nightly.zip"
        end
    end
end

#
# Main
#

if __FILE__ == $0
    g = GitHubDeployment::NightlyAppcastGenerator.new('iSoul.app', 'arranger1044', 'iSoul', 'http://arranger1044.github.com/iSoul/appcast-nightly.xml')
    
    puts('Generating...')
    g.generate('../appcast-nightly.xml')
    puts('Done!')
end
