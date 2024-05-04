import svgwrite
import cairosvg
import numpy as np

def create_card(rank, suit, filename):
    canvas_size = [300, 400]

    dwg = svgwrite.Drawing(filename, size=(f'{canvas_size[0]}px', f'{canvas_size[1]}px'), profile='full')
    
    # Map suits to Unicode characters
    suit_symbols = {
        'hearts': '♥',
        'diamonds': '♦',
        'clubs': '♣',
        'spades': '♠',
        'joker': '*'  # Using the Playing Card Black Joker symbol
    }
    suit_symbol = suit_symbols[suit]

    # Background with rounded corners
    corner_radius = '20'
    corner_size = 70
    bg_color = svgwrite.rgb(233, 240, 243)
    border_color = svgwrite.rgb(94, 148, 167)
    border_width = 5
    dwg.add(dwg.rect(insert=(border_width, border_width), size=(canvas_size[0]-border_width*2, canvas_size[1]-border_width*2), fill=bg_color, rx=corner_radius, ry=corner_radius, stroke=border_color, stroke_width=border_width))
    
    # Card rank and suit in the top left corner
    text_color = 'black'
    if suit in ['diamonds']:
        text_color = svgwrite.rgb(235, 89, 38)
    if suit in ['hearts']:
        text_color = svgwrite.rgb(228, 27, 73)
    dwg.add(dwg.text(rank, insert=(20+border_width, corner_size+border_width), fill=text_color, font_size=corner_size))

    dwg.add(dwg.text(suit_symbol, insert=(20+border_width, corner_size*2+border_width), fill=text_color, font_size=corner_size))
    
    # Card rank and suit in the bottom right corner (rotated)
    # Adjusting the position to ensure it's visible and correctly placed
    dwg.add(dwg.text(rank, insert=(260-border_width, 440-border_width-corner_size), fill=text_color, font_size=corner_size, transform=f'rotate(180, {270-border_width}, {420-border_width-corner_size})'))
    dwg.add(dwg.text(suit_symbol, insert=(260-border_width, 370-border_width-corner_size), fill=text_color, font_size=corner_size, transform=f'rotate(180, {270-border_width}, {350-border_width-corner_size})'))
    
    # Handle face cards separately
    # Face card graphics
    if suit == 'joker':
        # Special design for Joker
        text_color = 'purple'
        #dwg.add(dwg.text('Joker', insert=(75, 200), fill=text_color, font_size=50))
        # Example graphic for Joker (a jester hat)
        dwg.add(dwg.path(d="M150 100 Q120 150 150 200 Q180 150 150 100", fill=text_color))
        dwg.add(dwg.circle(center=(150, 100), r=10, fill=text_color))
    elif rank == 'J':
        # Example: Draw a simple crown for Jack
        dwg.add(dwg.path(d="M150 180 L130 220 L170 220 Z", fill=text_color))  # Simple triangle crown
        dwg.add(dwg.circle(center=(150, 250), r=30, fill=text_color))  # Face
    elif rank == 'Q':
        # Example: Draw a simple tiara and necklace for Queen
        dwg.add(dwg.path(d="M120 180 Q150 160 180 180 T240 180", fill=text_color))  # Tiara
        dwg.add(dwg.circle(center=(150, 250), r=30, fill=text_color))  # Face
        dwg.add(dwg.circle(center=(150, 300), r=10, fill=text_color))  # Necklace
    elif rank == 'K':
        # Example: Draw a simple crown and beard for King
        dwg.add(dwg.path(d="M120 180 L150 150 L180 180 L210 150 L240 180", fill=text_color))  # Crown
        dwg.add(dwg.circle(center=(150, 250), r=30, fill=text_color))  # Face
        dwg.add(dwg.rect(insert=(135, 280), size=('30', '20'), fill=text_color))  # Beard
    else:
        # Add suit symbols in the center for numbered cards
        num_symbols = int(rank) if rank.isdigit() else 1
        symbol_x, symbol_y = 100, 100
        
        if num_symbols % 2 == 1:
            dwg.add(dwg.text(suit_symbol, insert=(150, 200), fill=text_color, font_size='60', font_family='Arial', text_anchor="middle", dominant_baseline="middle"))
            
        if num_symbols >= 2 and num_symbols < 4:
            step_y = 100  # Distribute symbols vertically
            for i in range(num_symbols):
                dwg.add(dwg.text(suit_symbol, insert=(symbol_x, symbol_y + step_y * (i % (num_symbols // 2))), fill=text_color, font_size='60', font_family='Arial',text_anchor="middle", dominant_baseline="middle"))
                if i == num_symbols // 2 - 1:
                    symbol_x = 200  # Move to the right side for the next symbols
        if num_symbols >= 4:
            step_y = 200 / ((num_symbols-2) // 2)  # Distribute symbols vertically
            for i in range(num_symbols):
                ypos = symbol_y + step_y * (i % (num_symbols // 2))

                dwg_params = {}

                if ypos > canvas_size[1]//2:
                    dwg_params['transform_comp'] = f'rotate(180, {symbol_x}, {ypos})'
            
                dwg.add(dwg.text(suit_symbol, insert=(symbol_x, ypos), fill=text_color, font_size='60', font_family='Arial',text_anchor="middle", dominant_baseline="middle", **dwg_params))
                if i == num_symbols // 2 - 1:
                    symbol_x = 200  # Move to the right side for the next symbols


    dwg.save()

def create_card_back(filename):
    canvas_size = [300, 400]
    dwg = svgwrite.Drawing(filename, size=(f'{canvas_size[0]}px', f'{canvas_size[1]}px'), profile='tiny')
    
    # Background with rounded corners
    bg_color = svgwrite.rgb(10, 100, 150)  # Dark blue background
    border_color = svgwrite.rgb(255, 255, 255)  # White border
    border_width = 10
    dwg.add(dwg.rect(insert=(0, 0), size=(canvas_size[0], canvas_size[1]), fill=bg_color, rx='20', ry='20', stroke=border_color, stroke_width=border_width))
    
    # Central decorative motif (e.g., a diamond shape)
    center_x, center_y = canvas_size[0] // 2, canvas_size[1] // 2
    motif_color = svgwrite.rgb(255, 215, 0)  # Gold color
    dwg.add(dwg.polygon(points=[(center_x, center_y - 50), (center_x + 50, center_y), (center_x, center_y + 50), (center_x - 50, center_y)], fill=motif_color))
    
    # Additional decorative elements (e.g., smaller diamonds around the central motif)
    offset = 60
    for dx, dy in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
        x = center_x + dx * offset
        y = center_y + dy * offset
        dwg.add(dwg.polygon(points=[(x, y - 30), (x + 30, y), (x, y + 30), (x - 30, y)], fill=motif_color))
    
    # Save the SVG file
    dwg.save()

def convert_svg_to_png(svg_filename, png_filename):
    cairosvg.svg2png(url=svg_filename, write_to=png_filename)
    print(f'Created {png_filename}')

def main():
    suits = ['hearts', 'diamonds', 'clubs', 'spades']
    ranks = ['A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K']
    
    for suit in suits:
        for rank in ranks:
            svg_filename = f'godot/cards/{rank}_{suit}.svg'
            png_filename = f'godot/cards/{rank}_{suit}.png'
            create_card(rank, suit, svg_filename)
            convert_svg_to_png(svg_filename, png_filename)

    # Create Joker cards
    svg_filename = f'godot/cards/joker.svg'
    png_filename = f'godot/cards/joker.png'
    create_card('joker', 'joker', svg_filename)
    convert_svg_to_png(svg_filename, png_filename)
    
    create_card_back('godot/cards/back.svg')
    convert_svg_to_png('godot/cards/back.svg','godot/cards/back.png')


if __name__ == '__main__':
    main()