require 'asciidoctor'

class KillDummy < Asciidoctor::Converter.for('pdf')
    register_for 'pdf'

      def convert_inline_anchor node
        doc = node.document
        target = node.target
        case node.type
        when :link
          anchor = node.id ? %(<a id="#{node.id}">#{DummyText}</a>) : ''
          class_attr = ''
          if (role = node.role)
            class_attr = %( class="#{role}")
          end
          if (@media ||= doc.attr 'media', 'screen') != 'screen' && (target.start_with? 'mailto:')
            if (bare_target = target.slice 7, target.length) == (text = node.text)
              role = role ? role + ' bare' : 'bare'
            end
            bare_target = target unless doc.attr? 'hide-uri-scheme'
          else
            bare_target = target
            text = node.text
          end
          if role && (role == 'bare' || ((roles = role.split).include? 'bare'))
            # QUESTION: should we insert breakable chars into URI when building fragment instead?
            text = breakable_uri text if role == 'bare' || !(roles.include? 'nobreak')
            %(#{anchor}<a href="#{target}"#{class_attr}>#{text}</a>)
          # NOTE: @media may not be initialized if method is called before convert phase
          elsif (doc.attr? 'show-link-uri') || (@media != 'screen' && (doc.attr_unspecified? 'show-link-uri'))
            # QUESTION: should we insert breakable chars into URI when building fragment instead?
            # TODO: allow style of printed link to be controlled by theme
            %(#{anchor}<a href="#{target}"#{class_attr}>#{text}</a> [<font size="0.85em">#{breakable_uri bare_target}</font>&#93;)
          else
            %(#{anchor}<a href="#{target}"#{class_attr}>#{text}</a>)
          end
        when :xref
          # NOTE: non-nil path indicates this is an inter-document xref that's not included in current document
          if (path = node.attributes['path'])
            # NOTE: we don't use local as that doesn't work on the web
            %(<a href="#{target}">#{node.text || path}</a>)
          elsif (refid = node.attributes['refid'])
            if !(text = node.text) && AbstractNode === (ref = doc.catalog[:refs][refid]) && (@resolving_xref ||= (outer = true)) && outer
              if (text = ref.xreftext node.attr 'xrefstyle', nil, true)&.include? '<a'
                text = text.gsub DropAnchorRx, ''
              end
              if ref.inline? && ref.type == :bibref && !scratch? && (@bibref_refs.add? refid)
                anchor = %(<a id="_bibref_ref_#{refid}">#{DummyText}</a>)
              end
              @resolving_xref = nil
            end
            %(#{anchor || ''}<a anchor="#{derive_anchor_from_id refid}">#{text || "[#{refid}]"}</a>).gsub ']', '&#93;'
          else
            %(<a anchor="#{doc.attr 'pdf-anchor'}">#{node.text || '[^top&#93;'}</a>)
          end
        when :ref
            puts "REF"
          # NOTE: destination is created inside callback registered by FormattedTextTransform#build_fragment
          ## 2024-10-02 BYB: 
          %(<a id="#{node.id}">#{DummyText}</a>)
        #   %(<a id="#{node.id}"></a>)
        when :bibref
          id = node.id
          # NOTE: technically node.text should be node.reftext, but subs have already been applied to text
          reftext = (reftext = node.reftext) ? %([#{reftext}]) : %([#{id}])
          reftext = %(<a anchor="_bibref_ref_#{id}">#{reftext}</a>) if @bibref_refs.include? id
          # NOTE: destination is created inside callback registered by FormattedTextTransform#build_fragment
          %(<a id="#{id}">#{DummyText}</a>#{reftext})
        else
          log :warn, %(unknown anchor type: #{node.type.inspect})
          nil
        end
      end
    end