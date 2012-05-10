#!/usr/bin/env ruby -KU
# encoding: utf-8
#
# Code Author: David Jennes

module GitHubDeployment
    class SparkleSignature
        def self.calculate(archive, key)
            sign = %x[openssl dgst -sha1 -binary < '#{archive}' | openssl dgst -dss1 -sign '#{key}' | openssl enc -base64]
       
            # escape some special characters
            return sign.chomp.gsub(/([\+\/])/, '\\\\\1')
        end
    end
end

if __FILE__ == $0
    if ARGV.length < 2
        puts("Usage: #{File.basename($0)} ARCHIVE KEYFILE")
        exit(1)
    end
    
    puts GitHubDeployment::SparkleSignature.calculate(ARGV[0], ARGV[1])
end
