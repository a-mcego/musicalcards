import svgwrite
import os
import cairosvg

import numpy as np

def create_card(rank, suit, filename):
    canvas_size = [300, 400]
    
    font = {}
    corner_font_size = 60
    
    if suit == 'joker':
        font['font_family'] = "Noto Emoji"
        font['font_weight'] = "900"
        corner_font_size = 40
    
    centerify = {"text_anchor":"middle", "dominant_baseline":"middle"}

    dwg = svgwrite.Drawing(filename, size=(f'{canvas_size[0]}px', f'{canvas_size[1]}px'), profile='full')
    
    # Map suits to Unicode characters
    suit_symbols = {
        'hearts': '♥',
        'diamonds': '♦',
        'clubs': '♣',
        'spades': '♠',
        'joker': ''
    }
    suit_symbol = suit_symbols[suit]

    # Background with rounded corners
    corner_radius = 20
    bg_color = svgwrite.rgb(233, 240, 243)
    border_color = svgwrite.rgb(148, 148, 167)
    border_width = 5
    dwg.add(dwg.rect(insert=(border_width, border_width), size=(canvas_size[0]-border_width*2, canvas_size[1]-border_width*2), fill=bg_color, rx=corner_radius, ry=corner_radius, stroke=border_color, stroke_width=border_width))
    
    text_color = 'black'
    if suit in ['diamonds']:
        text_color = svgwrite.rgb(235, 89, 38)
    if suit in ['hearts']:
        text_color = svgwrite.rgb(228, 27, 73)
    if suit == 'joker':
        text_color = 'purple'

    # Card rank and suit in the top left corner
    rank_pos = (corner_radius+15, corner_radius+30)
    inv_rank_pos = (canvas_size[0]-rank_pos[0], canvas_size[1]-rank_pos[1])
    symbol_shift = 55
    
    dwg.add(dwg.text(rank, insert=rank_pos, fill=text_color, font_size=corner_font_size, letter_spacing="-5", **font,**centerify))
    dwg.add(dwg.text(suit_symbol, insert=(rank_pos[0], rank_pos[1]+symbol_shift), fill=text_color, font_size=corner_font_size, **font, **centerify))
    
    # Card rank and suit in the bottom right corner (rotated)
    dwg.add(dwg.text(rank, insert=inv_rank_pos, fill=text_color, font_size=corner_font_size, transform=f'rotate(180, {inv_rank_pos[0]}, {inv_rank_pos[1]})', letter_spacing="-5", **font, **centerify))
    dwg.add(dwg.text(suit_symbol, insert=(inv_rank_pos[0], inv_rank_pos[1]-symbol_shift), fill=text_color, font_size=corner_font_size, **font, transform=f'rotate(180, {inv_rank_pos[0]}, {inv_rank_pos[1]-symbol_shift})', **centerify))
    
    # Handle face cards separately
    # Face card graphics
    if suit == 'joker':
        dwg.add(dwg.text('🤡', insert=(canvas_size[0]*0.5, canvas_size[1]*0.5), fill=text_color, font_size='200', **font, **centerify))
    elif rank == 'J':
        font['font_family'] = "Noto Emoji"
        font['font_weight'] = "900"
        dwg.add(dwg.text('⚔', insert=(canvas_size[0]*0.5, canvas_size[1]*0.5), fill=text_color, font_size='180', **font, **centerify))
    elif rank == 'Q':
        font['font_family'] = "Noto Emoji"
        font['font_weight'] = "900"
        dwg.add(dwg.text('👸', insert=(canvas_size[0]*0.5, canvas_size[1]*0.5), fill=text_color, font_size='200', **font, **centerify))
    elif rank == 'K':
        font['font_family'] = "Noto Emoji"
        font['font_weight'] = "900"
        dwg.add(dwg.text('🤴', insert=(canvas_size[0]*0.5, canvas_size[1]*0.5), fill=text_color, font_size='200', **font, **centerify))
    else:
        # Add suit symbols in the center for numbered cards
        num_symbols = int(rank) if rank.isdigit() else 1
        symbol_x, symbol_y = 85, 70
        topleft = (symbol_x,symbol_y)
        bottomright = (canvas_size[0]-symbol_x, canvas_size[1]-symbol_y)
        sym_size = (bottomright[0]-topleft[0], bottomright[1]-topleft[1])
        if num_symbols == 1:
            dwg.add(dwg.text(suit_symbol, insert=(canvas_size[0]*0.5, canvas_size[1]*0.5), fill=text_color, font_size='240', **centerify))

        elif num_symbols >= 2 and num_symbols < 11:
            drawpoints = []
            if num_symbols == 2:
                drawpoints.extend([(0.5,0.0), (0.5,1.0)])
            elif num_symbols == 3:
                drawpoints.extend([(0.5,0.0), (0.5,0.5), (0.5,1.0)])
            elif num_symbols == 4:
                drawpoints.extend([(0.0,0.0), (0.0,1.0), (1.0,0.0), (1.0,1.0)])
            elif num_symbols == 5:
                drawpoints.extend([(0.0,0.0), (0.0,1.0), (1.0,0.0), (1.0,1.0), (0.5,0.5)])
            elif num_symbols == 6:
                drawpoints.extend([(0.0,0.0), (0.0, 0.5), (0.0,1.0), (1.0,0.0), (1.0, 0.5), (1.0,1.0)])
            elif num_symbols == 7:
                drawpoints.extend([(0.0,0.0), (0.0, 0.5), (0.0,1.0), (1.0,0.0), (1.0, 0.5), (1.0,1.0), (0.5,0.25)])
            elif num_symbols == 8:
                drawpoints.extend([(0.0,0.0), (0.0, 0.5), (0.0,1.0), (1.0,0.0), (1.0, 0.5), (1.0,1.0), (0.5,0.25), (0.5,0.75)])
            elif num_symbols == 9:
                drawpoints.extend([(0.0,0.0), (0.0,0.333), (0.0,0.667), (0.0,1.0), (1.0,0.0), (1.0,0.333), (1.0,0.667), (1.0,1.0), (0.5,0.5)])
            elif num_symbols == 10:
                drawpoints.extend([(0.0,0.0), (0.0,0.333), (0.0,0.667), (0.0,1.0), (1.0,0.0), (1.0,0.333), (1.0,0.667), (1.0,1.0), (0.5,0.166), (0.5,0.834)])
        
            for dp in drawpoints:
                xpos = topleft[0]+sym_size[0]*dp[0]
                ypos = topleft[1]+sym_size[1]*dp[1]
                dwg_params = {}
                if dp[1] > 0.5:
                    dwg_params['transform'] = f'rotate(180, {xpos}, {ypos})'
                dwg.add(dwg.text(suit_symbol, insert=(xpos, ypos), fill=text_color, font_size='90', font_family='Arial',text_anchor="middle", dominant_baseline="middle", **dwg_params))

        elif num_symbols >= 11:
            if num_symbols % 2 == 1:
                dwg.add(dwg.text(suit_symbol, insert=(canvas_size[0]*0.5, canvas_size[1]*0.5), fill=text_color, font_size='60', font_family='Arial', **centerify))
                
            step_y = 200 / ((num_symbols-2) // 2)  # Distribute symbols vertically
            for i in range(num_symbols):
                ypos = symbol_y + step_y * (i % (num_symbols // 2))
                dwg_params = {}
                if ypos > canvas_size[1]//2:
                    dwg_params['transform'] = f'rotate(180, {symbol_x}, {ypos})'
            
                dwg.add(dwg.text(suit_symbol, insert=(symbol_x, ypos), fill=text_color, font_size='60', font_family='Arial',**centerify, **dwg_params))
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
    create_card('⭐', 'joker', svg_filename)
    convert_svg_to_png(svg_filename, png_filename)
    
    create_card_back('godot/cards/back.svg')
    convert_svg_to_png('godot/cards/back.svg','godot/cards/back.png')


if __name__ == '__main__':
    main()