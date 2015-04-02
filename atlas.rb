
require 'nokogiri'


def atlas
  raise "Usage: ruby atlas.rb taxonomy_file destinations_file output_dir" unless ARGV.count == 3
  processor = AtlasProcessor.new(ARGV[0], ARGV[1], ARGV[2])
  processor.process_destinations()
end

class AtlasProcessor
  attr_accessor :taxonomy_doc, :destinations_doc, :output_dir

  def initialize(taxonomy_filename, destinations_filename, output_directory)
    self.taxonomy_doc = parse_file(taxonomy_filename)
    self.destinations_doc =  parse_file(destinations_filename)
    self.output_dir = output_directory
  end

  def parse_file(file)
    doc = File.open(file)
    parsed_doc = Nokogiri::XML(doc)
    doc.close
    parsed_doc
  end

  def process_destinations()
    template_file = Nokogiri::HTML(File.open("example.html"))
    taxonomy = Taxonomy.new(taxonomy_doc)

    destinations_doc.xpath("//destination").each do |dest|
      destination = Destination.new(dest, template_file.clone)
      destination.replace_title
      destination.replace_content
      destination.replace_navigation taxonomy
      File.open("#{output_dir}/#{destination.filename}", 'w') {|file| file.write(destination.template)}
    end
  end
end


class Destination
  attr_accessor :element, :template, :facts

  attr_accessor :section_title, :last_section_title

  def initialize(destination_element, content_template)
    self.element = destination_element
    self.template = content_template
    self.section_title = ''
    self.facts = []
    Fact.reset
  end

  def replace_title
    2.times do
      self.template.inner_html = template.inner_html.gsub(/\{DESTINATION NAME}/, title)
    end
  end

  def replace_content
    extract_facts element
    content_section[0].inner_html = facts.collect(&:to_html).join
  end
  
  def extract_facts current_element
    current_element.children.each do |element|
      next if element.content == "\n"
      if element.cdata?
        facts << Fact.new(element, section_title, facts.count)
      else
        self.section_title = titleize(element.name)
        extract_facts element
      end
    end
  end

  def replace_navigation taxonomy

    navigation = []
    node = taxonomy.get_node atlas_id

    parent = node.parent
    while parent.title do
      navigation << parent.link
      parent = parent.parent
    end
    navigation.reverse!
    navigation << node.link
    navigation << node.child_links

    nav_section[0].inner_html = navigation.join("<br>")
  end

  def atlas_id
    element.attributes['atlas_id'].value
  end

  def title
    element.attribute('title').content
  end

  def content_section
    template.xpath("//div[@id='main']//div[@class='content']/div[@class='inner']")
  end

  def nav_section
    template.xpath("//div[@id='sidebar']//div[@class='content']/div[@class='inner']")
  end

  def titleize string
    string.gsub(/_/,' ').split(/(\W)/).map(&:capitalize).join
  end

  def filename
    "#{atlas_id}_#{title.downcase}.html"
  end
end

class Fact
  attr_accessor :element, :title, :position

  def initialize(fact_element, title, position)
    self.element = fact_element
    self.position = position
    self.title = title
  end

  def self.reset
    @@last_title =''
  end

  def heading
    "<h3>#{title}</h3>" if title != @@last_title
  end

  def to_html
    html = "#{self.heading}<p>#{element.content}</p>"
    @@last_title = title
    html
  end

end

class Taxonomy
  attr_accessor :taxonomy

  def initialize(taxonomy_doc)
    self.taxonomy = taxonomy_doc
  end

  def get_node atlas_id
    TaxonomyNode.new(taxonomy.at_xpath("//node[@atlas_node_id='#{atlas_id}']"))
  end
end

class TaxonomyNode
  attr_accessor :node

  def initialize(taxonomy_node)
    self.node = taxonomy_node
  end

  def title
    node.at_xpath("node_name").content if node.at_xpath("node_name")
  end

  def atlas_id
    node.attributes['atlas_node_id']
  end

  def link
    "<a href='#{atlas_id}_#{title.downcase}.html'>#{title}</a>"
  end

  def parent
    TaxonomyNode.new(node.parent) if node.is_a?(Nokogiri::XML::Element) && node.parent
  end

  def child_links
    links = []
    node.children.each do |child|
      child_node = TaxonomyNode.new(child)
      links << child_node.link unless child_node.title.nil?
    end
    links
  end
end

atlas
