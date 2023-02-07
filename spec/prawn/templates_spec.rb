# frozen_string_literal: true

require_relative '../spec_helper'
require_relative '../../lib/prawn/templates'

DATADIR = "#{File.dirname(__FILE__)}/../../data"

describe Prawn::Templates do
  describe 'Document built from a template' do
    it 'has the same page count as the source document' do
      filename = "#{DATADIR}/pdfs/curves.pdf"
      pdf = Prawn::Document.new(template: filename)
      page_counter = PDF::Inspector::Page.analyze(pdf.render)

      expect(page_counter.pages.size).to eq 1

      filename = "#{DATADIR}/pdfs/multipage_template.pdf"
      pdf = Prawn::Document.new(template: filename)
      page_counter = PDF::Inspector::Page.analyze(pdf.render)

      expect(page_counter.pages.size).to eq 3
    end

    it 'recognizes a large page format' do
      # try with default margin of 72pt
      filename = "#{DATADIR}/pdfs/arch_e1.pdf"
      pdf = Prawn::Document.new(template: filename)
      expect(pdf.bounds.top_left).to eq [0, 2088]
      expect(pdf.bounds.width).to eq 72 * (42 - 1)
      expect(pdf.bounds.height).to eq 72 * (30 - 1)

      # set margin to 0 to confirm full-page bounds
      filename = "#{DATADIR}/pdfs/arch_e1.pdf"
      pdf = Prawn::Document.new(template: filename, margin: 0)
      expect(pdf.bounds.top_left).to eq [0, 2160]
      expect(pdf.bounds.width).to eq 72 * 42
      expect(pdf.bounds.height).to eq 72 * 30
    end

    it 'handles a document with a nil Contents entry' do
      filename = "#{DATADIR}/pdfs/corrupt_identifier_for_nil.pdf"
      expect do
        Prawn::Document.new(template: filename)
      end.to_not raise_error
    end

    it 'does not set the template page\'s parent to the document pages catalog'\
      ' (especially with nested pages)' do
      filename = "#{DATADIR}/pdfs/nested_pages.pdf"
      pdf = Prawn::Document.new(template: filename, skip_page_creation: true)
      expect(pdf.state.page.dictionary.data[:Parent]).to_not eq(
        pdf.state.store.pages
      )
    end

    it 'does start with the Y cursor at the top of the document' do
      filename = "#{DATADIR}/pdfs/curves.pdf"

      pdf = Prawn::Document.new(template: filename)
      expect(pdf.y).to_not be_nil
    end

    it 'respects margins set by Prawn' do
      filename = "#{DATADIR}/pdfs/curves.pdf"

      pdf = Prawn::Document.new(template: filename, margin: 0)
      expect(pdf.page.margins).to eq(
        left: 0,
        right: 0,
        top: 0,
        bottom: 0
      )

      pdf = Prawn::Document.new(template: filename, left_margin: 0)
      expect(pdf.page.margins).to eq(
        left: 0,
        right: 36,
        top: 36,
        bottom: 36
      )

      pdf.start_new_page(right_margin: 0)
      expect(pdf.page.margins).to eq(
        left: 0,
        right: 0,
        top: 36,
        bottom: 36
      )
    end

    it 'does not add an extra restore_graphics_state operator to the end of '\
        'any content stream' do
      filename = "#{DATADIR}/pdfs/curves.pdf"

      pdf = Prawn::Document.new(template: filename)
      output = StringIO.new(pdf.render)
      hash = PDF::Reader::ObjectHash.new(output)

      hash.each_value do |obj|
        next unless obj.is_a?(PDF::Reader::Stream)

        data = obj.data.tr(" \n\r", '')
        expect(data).to_not include 'QQ'
      end
    end

    it 'has a single page object if importing a single page template' do
      filename = "#{DATADIR}/pdfs/hexagon.pdf"

      pdf = Prawn::Document.new(template: filename)
      output = StringIO.new(pdf.render)
      hash = PDF::Reader::ObjectHash.new(output)

      pages =
        hash.values.select do |obj|
          obj.is_a?(Hash) && obj[:Type] == :Page
        end

      expect(pages.size).to eq 1
    end

    it 'has four content streams if importing a single page template' do
      filename = "#{DATADIR}/pdfs/hexagon.pdf"

      pdf = Prawn::Document.new(template: filename)
      output = StringIO.new(pdf.render)
      hash = PDF::Reader::ObjectHash.new(output)

      streams = hash.values.select { |obj| obj.is_a?(PDF::Reader::Stream) }

      expect(streams.size).to eq 4
    end

    it 'does not die if using this PDF as a template' do
      filename = "#{DATADIR}/pdfs/complex_template.pdf"

      expect do
        Prawn::Document.new(template: filename)
      end.to_not raise_error
    end

    it 'wraps and balances q/Q streams' do
      filename = "#{DATADIR}/pdfs/hexagon.pdf"

      pdf = Prawn::Document.new(template: filename)
      output = StringIO.new(pdf.render)
      hash = PDF::Reader::ObjectHash.new(output)

      page = hash.values.find { |obj| obj[:Type] == :Page }

      page[:Contents].each_with_index do |ref, i|
        stream_ref = hash.keys.find { |key| key.id == ref.id }
        stream = hash[stream_ref]
        data = stream.unfiltered_data

        case i
        when 0
          expect(data).to eq("q\n")
        when page[:Contents].length - 2
          expect(data).to eq("Q\n")
        else
          expect(data.scan('q').size).to eq(1)
          expect(data.scan('Q').size).to eq(1)
        end
      end
    end

    it 'allows text to be added to a single page template' do
      filename = "#{DATADIR}/pdfs/hexagon.pdf"

      pdf = Prawn::Document.new(template: filename)

      pdf.text 'Adding some text'

      text = PDF::Inspector::Text.analyze(pdf.render)
      expect(text.strings.first).to eq 'Adding some text'
    end

    it 'allows PDFs with page resources behind an indirect object to be used '\
        'as templates' do
      filename = "#{DATADIR}/pdfs/resources_as_indirect_object.pdf"

      pdf = Prawn::Document.new(template: filename)

      pdf.text 'Adding some text'

      text = PDF::Inspector::Text.analyze(pdf.render)
      all_text = text.strings.join
      expect(all_text).to include 'Adding some text'
    end

    it 'copies the PDF version from the template file' do
      filename = "#{DATADIR}/pdfs/version_1_6.pdf"

      pdf = Prawn::Document.new(template: filename)
      str = pdf.render
      expect(str[0, 8]).to eq '%PDF-1.6'
    end

    it 'correctly adds a TTF font to a template that has existing fonts' do
      filename = "#{DATADIR}/pdfs/contains_ttf_font.pdf"
      pdf = Prawn::Document.new(template: filename)
      pdf.font "#{DATADIR}/fonts/DejaVuSans.ttf"
      pdf.move_down(40)
      pdf.text 'Hi There'

      output = StringIO.new(pdf.render)
      hash = PDF::Reader::ObjectHash.new(output)

      page_dict =
        hash.values.find do |obj|
          obj.is_a?(Hash) && obj[:Type] == :Page
        end
      resources = page_dict[:Resources]
      fonts = resources[:Font]
      expect(fonts.size).to eq 2
    end

    it 'correctly imports a template file that is missing a MediaBox entry' do
      filename = "#{DATADIR}/pdfs/page_without_mediabox.pdf"

      pdf = Prawn::Document.new(template: filename)
      str = pdf.render
      expect(str[0, 4]).to eq '%PDF'
    end

    context 'with the template as a stream' do
      it 'correctly imports a template file from a stream' do
        filename = "#{DATADIR}/pdfs/hexagon.pdf"
        io = StringIO.new(File.binread(filename))
        pdf = Prawn::Document.new(template: io)
        str = pdf.render
        expect(str[0, 4]).to eq '%PDF'
      end
    end

    it 'merges metadata info' do
      filename = "#{DATADIR}/pdfs/hexagon.pdf"
      info = {
        Title: 'Sample METADATA',
        Author: 'Me',
        Subject: 'Not Working',
        CreationDate: Time.now
      }

      pdf = Prawn::Document.new(template: filename, info: info)
      output = StringIO.new(pdf.render)
      hash = PDF::Reader::ObjectHash.new(output)
      info.each_key do |k|
        expect(hash[hash.trailer[:Info]].key?(k)).to eq true
      end
    end

    it 'returns correct dimensions when :MediaBox is a reference' do
      filename = "#{DATADIR}/pdfs/page_with_mediabox_reference.pdf"
      pdf = Prawn::Document.new(template: filename)

      # expect the inherited value to be a reference
      # rubocop:disable Style/Send
      expect(pdf.state.page.send(:inherited_dictionary_value, :MediaBox)).to be_a PDF::Core::Reference
      # rubocop:enable Style/Send

      # expect dimensions to come back as an array
      expect(pdf.state.page.dimensions).to be_a Array
    end
  end

  describe 'Document#start_new_page with :template option' do
    filename = "#{DATADIR}/pdfs/curves.pdf"

    it "sets the imported page's parent to the document pages catalog" do
      pdf = Prawn::Document.new
      pdf.start_new_page(template: filename)
      expect(pdf.state.page.dictionary.data[:Parent]).to eq(
        pdf.state.store.pages
      )
    end

    it 'sets start the Y cursor at the top of the page' do
      pdf = Prawn::Document.new
      pdf.start_new_page(template: filename)
      expect(pdf.y).to_not be_nil
    end

    it 'respects margins set by Prawn' do
      pdf = Prawn::Document.new(margin: 0)
      pdf.start_new_page(template: filename)
      expect(pdf.page.margins).to eq(
        left: 0,
        right: 0,
        top: 0,
        bottom: 0
      )

      pdf = Prawn::Document.new(left_margin: 0)
      pdf.start_new_page(template: filename)
      expect(pdf.page.margins).to eq(
        left: 0,
        right: 36,
        top: 36,
        bottom: 36
      )
      pdf.start_new_page(template: filename, right_margin: 0)
      expect(pdf.page.margins).to eq(
        left: 0,
        right: 0,
        top: 36,
        bottom: 36
      )
    end

    it 'does not add an extra restore_graphics_state operator to the end of '\
        'any content stream' do
      pdf = Prawn::Document.new
      pdf.start_new_page(template: filename)
      output = StringIO.new(pdf.render)
      hash = PDF::Reader::ObjectHash.new(output)

      hash.each_value do |obj|
        next unless obj.is_a?(PDF::Reader::Stream)

        data = obj.data.tr(" \n\r", '')
        expect(data).to_not include 'QQ'
      end
    end

    it 'has two content streams if importing a single page template' do
      filename = "#{DATADIR}/pdfs/hexagon.pdf"
      pdf = Prawn::Document.new
      pdf.start_new_page(template: filename)
      output = StringIO.new(pdf.render)
      hash = PDF::Reader::ObjectHash.new(output)
      pages = hash.values.find do |obj|
        obj.is_a?(Hash) && obj[:Type] == :Pages
      end[:Kids]
      template_page = hash[pages[1]]
      expect(template_page[:Contents].size).to eq 2
    end

    it 'has balanced q/Q operators on all content streams' do
      filename = "#{DATADIR}/pdfs/hexagon.pdf"

      pdf = Prawn::Document.new
      pdf.start_new_page(template: filename)
      output = StringIO.new(pdf.render)
      hash = PDF::Reader::ObjectHash.new(output)

      streams = hash.values.select { |obj| obj.is_a?(PDF::Reader::Stream) }

      streams.each do |stream|
        data = stream.unfiltered_data
        expect(data.scan('q').size).to eq(1)
        expect(data.scan('Q').size).to eq(1)
      end
    end

    it 'allows text to be added to a single page template' do
      pdf = Prawn::Document.new
      pdf.start_new_page(template: filename)

      pdf.text 'Adding some text'

      text = PDF::Inspector::Text.analyze(pdf.render)
      expect(text.strings.first).to eq 'Adding some text'
    end

    it 'allows PDFs with page resources behind an indirect object to be used '\
        'as templates' do
      filename = "#{DATADIR}/pdfs/resources_as_indirect_object.pdf"

      pdf = Prawn::Document.new
      pdf.start_new_page(template: filename)

      pdf.text 'Adding some text'

      text = PDF::Inspector::Text.analyze(pdf.render)
      all_text = text.strings.join
      expect(all_text).to include 'Adding some text'
    end

    it 'correctly adds a TTF font to a template that has existing fonts' do
      filename = "#{DATADIR}/pdfs/contains_ttf_font.pdf"
      pdf = Prawn::Document.new
      pdf.start_new_page(template: filename)
      pdf.font "#{DATADIR}/fonts/DejaVuSans.ttf"
      pdf.move_down(40)
      pdf.text 'Hi There'

      output = StringIO.new(pdf.render)
      hash = PDF::Reader::ObjectHash.new(output)
      pages = hash.values.find do |obj|
        obj.is_a?(Hash) && obj[:Type] == :Pages
      end[:Kids]
      template_page = hash[pages[1]]
      resources = template_page[:Resources]
      fonts = resources[:Font]
      expect(fonts.size).to eq 2
    end

    it 'indexes template pages when used multiple times' do
      filename = "#{DATADIR}/pdfs/multipage_template.pdf"
      repeated_pdf = Prawn::Document.new
      3.times { repeated_pdf.start_new_page(template: filename) }
      repeated_hash = PDF::Reader::ObjectHash.new(
        StringIO.new(
          repeated_pdf.render
        )
      )
      sequential_pdf = Prawn::Document.new
      (1..3).each do |p|
        sequential_pdf.start_new_page(
          template: filename,
          template_page: p
        )
      end
      sequential_hash = PDF::Reader::ObjectHash.new(
        StringIO.new(
          sequential_pdf.render
        )
      )
      expect(repeated_hash.size == sequential_hash.size).to be_truthy
    end

    context 'with the template as a stream' do
      it 'correctly imports a template file from a stream' do
        filename = "#{DATADIR}/pdfs/hexagon.pdf"
        io = StringIO.new(File.binread(filename))

        pdf = Prawn::Document.new
        pdf.start_new_page(template: io)

        str = pdf.render
        expect(str[0, 4]).to eq '%PDF'
      end
    end

    context 'when using template_page option' do
      it 'uses the specified page option' do
        filename = "#{DATADIR}/pdfs/multipage_template.pdf"
        pdf = Prawn::Document.new
        pdf.start_new_page(template: filename, template_page: 2)
        text = PDF::Inspector::Text.analyze(pdf.render)
        expect(text.strings.first).to eq 'This is template page 2'
      end
    end
  end

  describe 'ObjectStore extensions' do
    before do
      @store = PDF::Core::ObjectStore.new
    end

    it 'imports objects from an existing PDF' do
      filename = "#{DATADIR}/pdfs/curves.pdf"
      store = PDF::Core::ObjectStore.new(template: filename)
      expect(store.size).to eq 5
    end

    it 'points to existing roots when importing objects from an existing PDF' do
      filename = "#{Prawn::BASEDIR}/spec/data/curves.pdf"
      store = PDF::Core::ObjectStore.new(template: filename)
      expect(store.info.class).to eq(PDF::Core::Reference)
      expect(store.root.class).to eq(PDF::Core::Reference)
    end

    it 'initializes with pages when importing objects from an existing PDF' do
      filename = "#{DATADIR}/pdfs/curves.pdf"
      store = PDF::Core::ObjectStore.new(template: filename)
      expect(store.pages.data[:Count]).to eq 1
    end

    it 'imports all objects from a PDF that has an indirect reference in a '\
        'stream dict' do
      filename = "#{DATADIR}/pdfs/indirect_reference.pdf"
      store = PDF::Core::ObjectStore.new(template: filename)
      expect(store.size).to eq 8
    end

    it 'raises error ArgumentError when given a file that doesn exist as a '\
        'template' do
      filename = 'not_really_there.pdf'

      expect { PDF::Core::ObjectStore.new(template: filename) }.to raise_error(
        ArgumentError
      )
    end

    it 'raises error PDF::Core::Errors::TemplateError when given a non PDF as '\
        'a template' do
      filename = "#{DATADIR}/images/dice.png"

      expect { PDF::Core::ObjectStore.new(template: filename) }.to raise_error(
        PDF::Core::Errors::TemplateError
      )
    end

    it 'raises error PDF::Core::Errors::TemplateError when given an encrypted '\
        'PDF as a template' do
      filename = "#{DATADIR}/pdfs/encrypted.pdf"

      expect { PDF::Core::ObjectStore.new(template: filename) }.to raise_error(
        PDF::Core::Errors::TemplateError
      )
    end
  end

  describe 'ObjectStore#object_id_for_page' do
    it 'returns the object ID of an imported template page' do
      filename = "#{DATADIR}/pdfs/hexagon.pdf"
      store = PDF::Core::ObjectStore.new(template: filename)
      expect(store.object_id_for_page(0)).to eq 4
    end

    it 'returns the object ID of the first imported template page' do
      filename = "#{DATADIR}/pdfs/two_hexagons.pdf"
      store = PDF::Core::ObjectStore.new(template: filename)
      expect(store.object_id_for_page(1)).to eq 4
    end

    it 'returns the object ID of the last imported template page' do
      filename = "#{DATADIR}/pdfs/two_hexagons.pdf"
      store = PDF::Core::ObjectStore.new(template: filename)
      expect(store.object_id_for_page(-1)).to eq 6
    end

    it 'returns the object ID of the first page of a template that uses nested'\
        ' Pages' do
      filename = "#{DATADIR}/pdfs/nested_pages.pdf"
      store = PDF::Core::ObjectStore.new(template: filename)
      expect(store.object_id_for_page(1)).to eq 5
    end

    it 'returns the object ID of the last page of a template that uses nested '\
        'Pages' do
      filename = "#{DATADIR}/pdfs/nested_pages.pdf"
      store = PDF::Core::ObjectStore.new(template: filename)
      expect(store.object_id_for_page(-1)).to eq 8
    end

    describe 'returns nil if given an invalid page number' do
      it 'with a template' do
        filename = "#{DATADIR}/pdfs/hexagon.pdf"
        store = PDF::Core::ObjectStore.new(template: filename)
        expect(store.object_id_for_page(10)).to eq nil
      end

      it 'without a template' do
        store = PDF::Core::ObjectStore.new
        expect(store.object_id_for_page(10)).to eq nil
      end
    end

    it 'accepts a stream instead of a filename' do
      example = Prawn::Document.new
      example.text 'An example doc, created in memory'
      example.start_new_page
      pdf = nil
      StringIO.open(example.render) do |stream|
        pdf = PDF::Core::ObjectStore.new(template: stream)
      end
      expect(pdf.page_count).to eq 2
    end
  end
end
