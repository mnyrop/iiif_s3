module IiifS3
  class Config

    # @return [String] The default URL to append to all IDs.
    DEFAULT_URL = "http://0.0.0.0"
    # @return [String] The name of the subdirectory where generated images live 
    DEFAULT_IMAGE_DIRECTORY_NAME = "images"
    # @return [String] The default path for writing generated images and data files
    DEFAULT_OUTPUT_DIRECTORY = "./build"
    # @return [Number] The default tile width/height in pixels
    DEFAULT_TILE_WIDTH = 512
    # @return [Array<Number>] The default tile scaling factors
    DEFAULT_TILE_SCALE_FACTORS = [1,2,4,8]
    # @return [Number] The default thumnail size in pixels
    DEFAULT_THUMBNAIL_SIZE = 250    

    #
    # @!attribute [r] base_uri
    #   @return [String] The protocol, domain, and port used for generating URIs.
    #   @default IiifS3::Config::DEFAULT_URL
    attr_reader :base_uri
    #
    # @!attribute [r] use_extensions
    #   @return [Boolean] Should generated IDs and files have a .json extension?
    #   @default true
    attr_reader :use_extensions
    #
    # @!attribute [r] output_dir
    #   @return [String] The directory on the local file system where the output
    #     files should be saved
    #     @default IiifS3::Config::DEFAULT_OUTPUT_DIRECTORY
    attr_reader :output_dir
    #
    # @!attribute [r] prefix
    #   @return [String] A prefix to be appended between the base URI and the id.
    #     Can be blank,and it will automatically prepend a slash if one is not
    #     provided.
    #   @default ""
    attr_reader :prefix
    #
    # @!attribute [r] image_directory_name
    #   @return [String] The name of the directory/prefix where image files will be
    #   located.
    #   @default IiifS3::Config::DEFAULT_IMAGE_DIRECTORY_NAME
    attr_reader :image_directory_name
    #
    # @!attribute [r] tile_width
    #   @return [Number] The width (and height) of each individual tile.
    #   @default IiifS3::Config::DEFAULT_TILE_WIDTH
    attr_reader :tile_width
    #
    # @!attribute [r] tile
    #   @return [Array<Number>] An array of tile ratios to be uploaded.
    #   @default IiifS3::Config::DEFAULT_TILE_SCALE_FACTORS
    attr_reader :tile_scale_factors
    #
    # @!attribute [r] variants
    #   @return [Hash] A Hash of key/value pairs.  Each key should be the name of a variant,
    #     each value the maximum pixel dimension of the longest side.
    #   @default {}
    attr_reader :variants
    #
    # @!attribute [r] upload_to_s3
    #   @return [Boolean] Should the files that are created by automatically uploaded to Amazon S3?
    #   @default false
    attr_reader :upload_to_s3

    # @!attribute [r] thumbnail_size
    #   @return [Number] The max width in pixels for a thumbnail image
    attr_reader :thumbnail_size

    # @!attribute [r] verbose
    #   @return [Bool] Should the program log information to the console?
    attr_reader :verbose
    alias :verbose? :verbose

    def initialize(opts = {})

      @upload_to_s3 = opts[:upload_to_s3] || false
      @s3 = IiifS3::AmazonS3.new if @upload_to_s3
      @tile_width = opts[:tile_width] || DEFAULT_TILE_WIDTH
      @tile_scale_factors = opts[:tile_scale_factors] || DEFAULT_TILE_SCALE_FACTORS
      @image_directory_name = opts[:image_directory_name] || DEFAULT_IMAGE_DIRECTORY_NAME
      @base_uri = opts[:base_uri] || ( @upload_to_s3 ? @s3.bucket.url : DEFAULT_URL)
      @use_extensions = opts[:use_extensions].nil? ? true : opts[:use_extensions]
      @output_dir = opts[:output_dir] || DEFAULT_OUTPUT_DIRECTORY
      @image_dir = @output_dir
      @variants = opts[:variants] || {}
      @prefix = opts[:prefix] || ""
      if @prefix.length > 0 && @prefix[0] != "/"
        @prefix = "/#{@prefix}" 
      end
      @thumbnail_size = opts[:thumbnail_size] || DEFAULT_THUMBNAIL_SIZE
      verbose = opts.fetch(:verbose, false)
    end

    def build_location(id)
      "#{output_dir}#{prefix}/#{id}"
    end

    def build_image_location(id, page_number)
      "#{output_dir}#{prefix}/#{image_directory_name}/#{id}-#{page_number}"
    end

    def add_default_redirect(filename) 
      return unless  @upload_to_s3
      key = filename.gsub(output_dir,"")
      key = key[1..-1] if key[0] == "/"

      name_key = key.split(".")[0..-2].join(".")

      unless key == name_key
        key = "#{@base_uri}/#{key}"
        puts "adding redirect from #{name_key} to #{key}" if verbose?
        @s3.add_redirect(name_key, key)
      end
    end

    def add_file_to_s3(filename)
      return unless @upload_to_s3
      key = filename.gsub(output_dir,"")
      key = key[1..-1] if key[0] == "/"
      if File.extname(filename) == ".json" || File.extname(filename)  == ""
        @s3.add_json(key,filename) 
      elsif  File.extname(filename) == ".jpg" 
        @s3.add_image(key,filename)
      else
        raise "Cannot identify file type!"
      end
    end

    # Compare two configuration files
    #
    # @param [IiifS3::Config] other_config The configuration file to compare
    #
    # @return [Bool] True if they are the same, false otherwise
    # 
    def ==(other_config)
      valid = true
      self.instance_variables.each do |v|
        valid &&= instance_variable_get(v) == other_config.instance_variable_get(v)
      end
      valid
    end

    # Set if the application should log debugging data to the console
    #
    # @param [Bool] val
    # @return [Bool] 
    def verbose=(val)
      @verbose = !!val
    end
  end
end