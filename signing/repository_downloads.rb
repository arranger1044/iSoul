#!/usr/bin/env ruby -KU
# encoding: utf-8
#
# Code Author: David Jennes

require 'optparse'
require 'rubygems'
require 'github_api'

module GitHubDeployment
    class RepositoryDownloads
        
        # Client configuration
        CLIENT_ID = '3b0893da2443e2672ce4'
        CLIENT_SECRET = '8d1d93ae656ff2e23e95d7b97afab90fb988a5e2'
        TOKEN_FILE = 'access_token.data'
        
        # attributes
        attr_accessor :user, :repo
        
        # Constructor
        # username: The repository's username
        # repository: The repository's actual name
        def initialize(username, repository)
            @user = username
            @repo = repository
            
            @token = loadAccessToken()
            @github = Github.new(:oauth_token => @token)
        end
        
        # Create a new download in the specified repository
        # path: Path to where the download file is located
        # name: Desired download name
        # description: Description for the new download
        # returns: The URL for the new download
        def create(path, name, description)
            raise 'Could not find file' if !File.exists?(path)
            
            # delete old file (otherwise we'll get an error during creation)
            @github.repos.downloads.all(@user, @repo).find_all { |d|
                d.name == name
            }.each { |d|
                @github.repos.downloads.delete(@user, @repo, d.id)
            }
            
            # create
            res = @github.repos.downloads.create(@user, @repo,
                                                'name' => name,
                                                'size' => File.size(path),
                                                'description' => description)
            
            # upload
            @github.repos.downloads.upload(res, path)
            
            return res.html_url
        end

        # List available downloads in a repository
        def list()
            puts('Available downloads:')
            @github.repos.downloads.all(@user, @repo).each { |down|
                puts(" - #{down.name} (#{down.description})")
            }
        end
        
        private
        
        # Load our stored access token if available, otherwise create one
        # returns: the OAuth token hash
        def loadAccessToken
            token = nil
            
            begin
                File.open(TOKEN_FILE, 'rb') { |f| token = Marshal.load(f) }
            rescue Errno::ENOENT => e
                puts('No access token available, registering with GitHub...')
                token = createAccessToken()
            end
            
            return token
        end
        
        # Create an access token with GitHub (and store it)
        # returns: a new OAuth token hash
        def createAccessToken
            github = Github.new(:client_id => CLIENT_ID, :client_secret => CLIENT_SECRET)
            
            # show authorization URL
            url = github.authorize_url(:scope => 'repo')
            puts('\nPlease follow the instructions in the browser window and paste the resulting code here.')
            sleep(2.0)
            puts('Opening url in default browser...')
            system("open \"#{url}\"")
            
            # get authorization code
            puts('Enter the authorization code:')
            STDOUT.flush
            authorization_code = gets.chomp
            
            # get token and store it
            access_token = github.get_token(authorization_code).token
            File.open(TOKEN_FILE, 'wb') { |f| Marshal.dump(access_token, f) }
            
            return access_token
        end
    end
end

#
# Main
#

if __FILE__ == $0
    options = {}
    
    # parse command line options
    optparse = OptionParser.new { |opts|
        script_name = File.basename($0)
        opts.banner = 'GitHub Repository Downloads Script',
            "\nUsage: #{script_name} [options] file"

        # Define the options, and what they do
        options[:description] = ''
        opts.on('-d', '--description DESC', 'Description of the new download') { |desc|
            options[:description] = desc
        }
        
        options[:name] = nil
        opts.on('-n', '--name NAME', 'Download name (default: same as filename)') { |name|
            options[:name] = name
        }

        opts.on('-r', '--repository REPO', 'Repository\'s name') { |repo|
            options[:repo] = repo
        }

        opts.on('-u', '--username USER', 'Repository\'s user') { |user|
            options[:user] = user
        }

        opts.on('-h', '--help', 'Display this screen') {
            puts(opts)
            exit(0)
        }
    }

    # extract flags and check for missing argument
    optparse.parse!()
    raise 'Missing path argument. Please use -h or --help for usage.' if ARGV.empty?
    raise 'Missing user argument. Please use -h or --help for usage.' if !options.has_key?(:user)
    raise 'Missing repo argument. Please use -h or --help for usage.' if !options.has_key?(:repo)
    
    # extract path
    options[:path] = ARGV.first
    if (!options[:name])
        options[:name] = options[:path]
    end
    
    # initialize
    downloads = GitHubDeployment::RepositoryDownloads.new(options[:user], options[:repo])
    
    # create download
    puts 'Creating download...'
    downloads.create(options[:path], options[:name], options[:description])

    # list downloads
    downloads.list()
end
