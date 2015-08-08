require_relative "spec_helper"
require_relative "../lib/prawn/templates"

DATADIR = "#{File.dirname(__FILE__)}/../data"

describe "Document built from a template" do
  it "should have the same page count as the source document" do
    filename = "#{DATADIR}/pdfs/curves.pdf"
    @pdf = Prawn::Document.new(:template => filename)
    page_counter = PDF::Inspector::Page.analyze(@pdf.render)

    expect(page_counter.pages.size).to eq 1
  end

  it "should not set the template page's parent to the document pages catalog (especially with nested pages)" do
    filename = "#{DATADIR}/pdfs/nested_pages.pdf"
    @pdf = Prawn::Document.new(:template => filename, :skip_page_creation => true)
    expect(@pdf.state.page.dictionary.data[:Parent]).to_not eq @pdf.state.store.pages
  end

  it "should have start with the Y cursor at the top of the document" do
    filename = "#{DATADIR}/pdfs/curves.pdf"

    @pdf = Prawn::Document.new(:template => filename)
    expect(@pdf.y.nil?).to be_falsey
  end

  it "should respect margins set by Prawn" do
    filename = "#{DATADIR}/pdfs/curves.pdf"

    @pdf = Prawn::Document.new(:template => filename, :margin => 0)
    expect(@pdf.page.margins).to eq(:left   => 0,
                                    :right  => 0,
                                    :top    => 0,
                                    :bottom => 0)

    @pdf = Prawn::Document.new(:template => filename, :left_margin => 0)
    expect(@pdf.page.margins).to eq(:left   => 0,
                                    :right  => 36,
                                    :top    => 36,
                                    :bottom => 36)

    @pdf.start_new_page(:right_margin => 0)
    expect(@pdf.page.margins).to eq(:left   => 0,
                                    :right  => 0,
                                    :top    => 36,
                                    :bottom => 36)
  end

  it "should not add an extra restore_graphics_state operator to the end of any content stream" do
    filename = "#{DATADIR}/pdfs/curves.pdf"

    @pdf = Prawn::Document.new(:template => filename)
    output = StringIO.new(@pdf.render)
    hash = PDF::Reader::ObjectHash.new(output)

    hash.each_value do |obj|
      next unless obj.kind_of?(PDF::Reader::Stream)

      data = obj.data.tr(" \n\r", "")
      expect(data.include?("QQ")).to be_falsey
    end
  end

  it "should have a single page object if importing a single page template" do
    filename = "#{DATADIR}/pdfs/hexagon.pdf"

    @pdf = Prawn::Document.new(:template => filename)
    output = StringIO.new(@pdf.render)
    hash = PDF::Reader::ObjectHash.new(output)

    pages = hash.values.select { |obj| obj.kind_of?(Hash) && obj[:Type] == :Page }

    expect(pages.size).to eq 1
  end

  it "should have two content streams if importing a single page template" do
    filename = "#{DATADIR}/pdfs/hexagon.pdf"

    @pdf = Prawn::Document.new(:template => filename)
    output = StringIO.new(@pdf.render)
    hash = PDF::Reader::ObjectHash.new(output)

    streams = hash.values.select { |obj| obj.kind_of?(PDF::Reader::Stream) }

    expect(streams.size).to eq 2
  end

  it "should not die if using this PDF as a template" do
    filename = "#{DATADIR}/pdfs/complex_template.pdf"

    expect {
      @pdf = Prawn::Document.new(:template => filename)
    }.to_not raise_error
  end

  it "should have balance q/Q operators on all content streams" do
    filename = "#{DATADIR}/pdfs/hexagon.pdf"

    @pdf = Prawn::Document.new(:template => filename)
    output = StringIO.new(@pdf.render)
    hash = PDF::Reader::ObjectHash.new(output)

    streams = hash.values.select { |obj| obj.kind_of?(PDF::Reader::Stream) }

    streams.each do |stream|
      data = stream.unfiltered_data
      expect(data.scan("q").size).to eq(1)
      expect(data.scan("Q").size).to eq(1)
    end
  end

  it "should allow text to be added to a single page template" do
    filename = "#{DATADIR}/pdfs/hexagon.pdf"

    @pdf = Prawn::Document.new(:template => filename)

    @pdf.text "Adding some text"

    text = PDF::Inspector::Text.analyze(@pdf.render)
    expect(text.strings.first).to eq "Adding some text"
  end

  it "should allow PDFs with page resources behind an indirect object to be used as templates" do
    filename = "#{DATADIR}/pdfs/resources_as_indirect_object.pdf"

    @pdf = Prawn::Document.new(:template => filename)

    @pdf.text "Adding some text"

    text = PDF::Inspector::Text.analyze(@pdf.render)
    all_text = text.strings.join
    expect(all_text.include?("Adding some text")).to be_truthy
  end

  it "should copy the PDF version from the template file" do
    filename = "#{DATADIR}/pdfs/version_1_6.pdf"

    @pdf = Prawn::Document.new(:template => filename)
    str = @pdf.render
    expect(str[0, 8]).to eq "%PDF-1.6"
  end

  it "should correctly add a TTF font to a template that has existing fonts" do
    filename = "#{DATADIR}/pdfs/contains_ttf_font.pdf"
    @pdf = Prawn::Document.new(:template => filename)
    @pdf.font "#{DATADIR}/fonts/DejaVuSans.ttf"
    @pdf.move_down(40)
    @pdf.text "Hi There"

    output = StringIO.new(@pdf.render)
    hash = PDF::Reader::ObjectHash.new(output)

    page_dict = hash.values.detect{ |obj| obj.is_a?(Hash) && obj[:Type] == :Page }
    resources = page_dict[:Resources]
    fonts = resources[:Font]
    expect(fonts.size).to eq 2
  end

  it "should correctly import a template file that is missing a MediaBox entry" do
    filename = "#{DATADIR}/pdfs/page_without_mediabox.pdf"

    @pdf = Prawn::Document.new(:template => filename)
    str = @pdf.render
    expect(str[0, 4]).to eq "%PDF"
  end

  context "with the template as a stream" do
    it "should correctly import a template file from a stream" do
      filename = "#{DATADIR}/pdfs/hexagon.pdf"
      io = StringIO.new(File.binread(filename))
      @pdf = Prawn::Document.new(:template => io)
      str = @pdf.render
      expect(str[0, 4]).to eq "%PDF"
    end
  end

  it "merges metadata info" do
    filename = "#{DATADIR}/pdfs/hexagon.pdf"
    info = { :Title => "Sample METADATA",
             :Author => "Me",
             :Subject => "Not Working",
             :CreationDate => Time.now }

    @pdf = Prawn::Document.new(:template => filename, :info => info)
    output = StringIO.new(@pdf.render)
    hash = PDF::Reader::ObjectHash.new(output)
    info.keys.each { |k| expect(hash[hash.trailer[:Info]].keys.include?(k)).to eq true }
  end
end

describe "Document#start_new_page with :template option" do
  filename = "#{DATADIR}/pdfs/curves.pdf"

  it "should set the imported page's parent to the document pages catalog" do
    @pdf = Prawn::Document.new
    @pdf.start_new_page(:template => filename)
    expect(@pdf.state.page.dictionary.data[:Parent]).to eq @pdf.state.store.pages
  end

  it "should set start the Y cursor at the top of the page" do
    @pdf = Prawn::Document.new
    @pdf.start_new_page(:template => filename)
    expect(@pdf.y.nil?).to be_falsey
  end

  it "should respect margins set by Prawn" do
    @pdf = Prawn::Document.new(:margin => 0)
    @pdf.start_new_page(:template => filename)
    expect(@pdf.page.margins).to eq(:left   => 0,
                                    :right  => 0,
                                    :top    => 0,
                                    :bottom => 0)

    @pdf = Prawn::Document.new(:left_margin => 0)
    @pdf.start_new_page(:template => filename)
    expect(@pdf.page.margins).to eq(:left   => 0,
                                    :right  => 36,
                                    :top    => 36,
                                    :bottom => 36)
    @pdf.start_new_page(:template => filename, :right_margin => 0)
    expect(@pdf.page.margins).to eq(:left   => 0,
                                    :right  => 0,
                                    :top    => 36,
                                    :bottom => 36)
  end

  it "should not add an extra restore_graphics_state operator to the end of any content stream" do
    @pdf = Prawn::Document.new
    @pdf.start_new_page(:template => filename)
    output = StringIO.new(@pdf.render)
    hash = PDF::Reader::ObjectHash.new(output)

    hash.each_value do |obj|
      next unless obj.kind_of?(PDF::Reader::Stream)

      data = obj.data.tr(" \n\r", "")
      expect(data.include?("QQ")).to be_falsey
    end
  end

  it "should have two content streams if importing a single page template" do
    filename = "#{DATADIR}/pdfs/hexagon.pdf"
    @pdf = Prawn::Document.new
    @pdf.start_new_page(:template => filename)
    output = StringIO.new(@pdf.render)
    hash = PDF::Reader::ObjectHash.new(output)
    pages = hash.values.find { |obj| obj.is_a?(Hash) && obj[:Type] == :Pages }[:Kids]
    template_page = hash[pages[1]]
    expect(template_page[:Contents].size).to eq 2
  end

  it "should have balance q/Q operators on all content streams" do
    filename = "#{DATADIR}/pdfs/hexagon.pdf"

    @pdf = Prawn::Document.new
    @pdf.start_new_page(:template => filename)
    output = StringIO.new(@pdf.render)
    hash = PDF::Reader::ObjectHash.new(output)

    streams = hash.values.select { |obj| obj.kind_of?(PDF::Reader::Stream) }

    streams.each do |stream|
      data = stream.unfiltered_data
      expect(data.scan("q").size).to eq(1)
      expect(data.scan("Q").size).to eq(1)
    end
  end

  it "should allow text to be added to a single page template" do
    @pdf = Prawn::Document.new
    @pdf.start_new_page(:template => filename)

    @pdf.text "Adding some text"

    text = PDF::Inspector::Text.analyze(@pdf.render)
    expect(text.strings.first).to eq "Adding some text"
  end

  it "should allow PDFs with page resources behind an indirect object to be used as templates" do
    filename = "#{DATADIR}/pdfs/resources_as_indirect_object.pdf"

    @pdf = Prawn::Document.new
    @pdf.start_new_page(:template => filename)

    @pdf.text "Adding some text"

    text = PDF::Inspector::Text.analyze(@pdf.render)
    all_text = text.strings.join
    expect(all_text.include?("Adding some text")).to be_truthy
  end

  it "should correctly add a TTF font to a template that has existing fonts" do
    filename = "#{DATADIR}/pdfs/contains_ttf_font.pdf"
    @pdf = Prawn::Document.new
    @pdf.start_new_page(:template => filename)
    @pdf.font "#{DATADIR}/fonts/DejaVuSans.ttf"
    @pdf.move_down(40)
    @pdf.text "Hi There"

    output = StringIO.new(@pdf.render)
    hash = PDF::Reader::ObjectHash.new(output)
    hash = PDF::Reader::ObjectHash.new(output)
    pages = hash.values.find { |obj| obj.is_a?(Hash) && obj[:Type] == :Pages }[:Kids]
    template_page = hash[pages[1]]
    resources = template_page[:Resources]
    fonts = resources[:Font]
    expect(fonts.size).to eq 2
  end

  it "indexes template pages when used multiple times" do
    filename = "#{DATADIR}/pdfs/multipage_template.pdf"
    @repeated_pdf = Prawn::Document.new
    3.times { @repeated_pdf.start_new_page(:template => filename) }
    repeated_hash = PDF::Reader::ObjectHash.new(StringIO.new(@repeated_pdf.render))
    @sequential_pdf = Prawn::Document.new
    (1..3).each { |p| @sequential_pdf.start_new_page(:template => filename, :template_page => p) }
    sequential_hash = PDF::Reader::ObjectHash.new(StringIO.new(@sequential_pdf.render))
    expect(repeated_hash.size < sequential_hash.size).to be_truthy
  end

  context "with the template as a stream" do
    it "should correctly import a template file from a stream" do
      filename = "#{DATADIR}/pdfs/hexagon.pdf"
      io = StringIO.new(File.binread(filename))

      @pdf = Prawn::Document.new
      @pdf.start_new_page(:template => io)

      str = @pdf.render
      expect(str[0, 4]).to eq "%PDF"
    end
  end

  context "using template_page option" do
    it "uses the specified page option" do
      filename = "#{DATADIR}/pdfs/multipage_template.pdf"
      @pdf = Prawn::Document.new
      @pdf.start_new_page(:template => filename, :template_page => 2)
      text = PDF::Inspector::Text.analyze(@pdf.render)
      expect(text.strings.first).to eq "This is template page 2"
    end
  end
end

describe "ObjectStore extensions" do
  before(:each) do
    @store = PDF::Core::ObjectStore.new
  end

  it "should import objects from an existing PDF" do
    filename = "#{DATADIR}/pdfs/curves.pdf"
    store = PDF::Core::ObjectStore.new(:template => filename)
    expect(store.size).to eq 5
  end

  it "should point to existing roots when importing objects from an existing PDF" do
    filename = "#{Prawn::BASEDIR}/spec/data/curves.pdf"
    store = PDF::Core::ObjectStore.new(:template => filename)
    expect(store.info.class).to eq(PDF::Core::Reference)
    expect(store.root.class).to eq(PDF::Core::Reference)
  end

  it "should initialize with pages when importing objects from an existing PDF" do
    filename = "#{DATADIR}/pdfs/curves.pdf"
    store = PDF::Core::ObjectStore.new(:template => filename)
    expect(store.pages.data[:Count]).to eq 1
  end

  it "should import all objects from a PDF that has an indirect reference in a stream dict" do
    filename = "#{DATADIR}/pdfs/indirect_reference.pdf"
    store = PDF::Core::ObjectStore.new(:template => filename)
    expect(store.size).to eq 8
  end

  it "should raise_error ArgumentError when given a file that doesn exist as a template" do
    filename = "not_really_there.pdf"

    expect { PDF::Core::ObjectStore.new(:template => filename) }.to raise_error(ArgumentError)
  end

  it "should raise_error PDF::Core::Errors::TemplateError when given a non PDF as a template" do
    filename = "#{DATADIR}/images/dice.png"

    expect { PDF::Core::ObjectStore.new(:template => filename) }.to raise_error(PDF::Core::Errors::TemplateError)
  end

  it "should raise_error PDF::Core::Errors::TemplateError when given an encrypted PDF as a template" do
    filename = "#{DATADIR}/pdfs/encrypted.pdf"

    expect { PDF::Core::ObjectStore.new(:template => filename) }.to raise_error(PDF::Core::Errors::TemplateError)
  end
end

describe "ObjectStore#object_id_for_page" do
  it "should return the object ID of an imported template page" do
    filename = "#{DATADIR}/pdfs/hexagon.pdf"
    store = PDF::Core::ObjectStore.new(:template => filename)
    expect(store.object_id_for_page(0)).to eq 4
  end

  it "should return the object ID of the first imported template page" do
    filename = "#{DATADIR}/pdfs/two_hexagons.pdf"
    store = PDF::Core::ObjectStore.new(:template => filename)
    expect(store.object_id_for_page(1)).to eq 4
  end

  it "should return the object ID of the last imported template page" do
    filename = "#{DATADIR}/pdfs/two_hexagons.pdf"
    store = PDF::Core::ObjectStore.new(:template => filename)
    expect(store.object_id_for_page(-1)).to eq 6
  end

  it "should return the object ID of the first page of a template that uses nested Pages" do
    filename = "#{DATADIR}/pdfs/nested_pages.pdf"
    store = PDF::Core::ObjectStore.new(:template => filename)
    expect(store.object_id_for_page(1)).to eq 5
  end

  it "should return the object ID of the last page of a template that uses nested Pages" do
    filename = "#{DATADIR}/pdfs/nested_pages.pdf"
    store = PDF::Core::ObjectStore.new(:template => filename)
    expect(store.object_id_for_page(-1)).to eq 8
  end

  it "should return nil if given an invalid page number" do
    filename = "#{DATADIR}/pdfs/hexagon.pdf"
    store = PDF::Core::ObjectStore.new(:template => filename)
    expect(store.object_id_for_page(10)).to eq nil
  end

  it "should return nil if given an invalid page number" do
    store = PDF::Core::ObjectStore.new
    expect(store.object_id_for_page(10)).to eq nil
  end

  it "should accept a stream instead of a filename" do
    example = Prawn::Document.new
    example.text "An example doc, created in memory"
    example.start_new_page
    StringIO.open(example.render) do |stream|
      @pdf = PDF::Core::ObjectStore.new(:template => stream)
    end
    expect(@pdf.page_count).to eq 2
  end
end
