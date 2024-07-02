#!/usr/bin/env python3
# Copyright 2024 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Lukas Berner <bernerl@student.ethz.ch>

import math
import random
import argparse
import subprocess
import os
import pygame as pg
import pygame.gfxdraw

ANIMATION_LENGTH_SECONDS = 2
NUM_FRAMES = ANIMATION_LENGTH_SECONDS * 20

IMG_HEIGHT = 400
IMG_WIDTH = 400

# parse arguments
parser = argparse.ArgumentParser()
parser.add_argument("--out_dir", type=str, default="util/traffic_visualizations")
parser.add_argument("--gif", type=int, default=0)
parser.add_argument("--num_x", type=int, default=4)
parser.add_argument("--num_y", type=int, default=4)
parser.add_argument("--traffic_type", type=str, default="all")
parser.add_argument("--rw", type=str, default="write")
args = parser.parse_args()
NUM_X = args.num_x
NUM_Y = args.num_y

def clog2(x: int):
    """Compute the ceiling of the log2 of x."""
    return (x - 1).bit_length()


def gen_mesh_traffic():
    # pylint: disable=too-many-arguments, too-many-locals, too-many-branches, too-many-statements
    """Generate Mesh traffic."""
    jobs = []
    for x in range(1, NUM_X + 1):
        for y in range(1, NUM_Y + 1):
            local_addr = (x, y)
            if args.traffic_type == "hbm":
                # Tile x=0 are the HBM channels
                # Each core read from the channel of its y coordinate
                ext_addr = (0, y)
            elif args.traffic_type == "random":
                ext_addr = local_addr
                while ext_addr == local_addr:
                    ext_addr = (random.randint(1, NUM_X), random.randint(1, NUM_Y))
            elif args.traffic_type == "onehop":
                if not (x == 1 and y == 1):
                    local_addr = (0, 0)
                    ext_addr = (0, 0)
                else:
                    ext_addr = (x, y + 1)
            elif args.traffic_type == "bit_complement":
                ext_addr = (NUM_X - x + 1, NUM_Y - y + 1)
            elif args.traffic_type == "bit_reverse":
                # in order to achieve same result as garnet:
                # change to space where addresses start at 0 and return afterwards
                straight = x-1 + (y-1) * NUM_X
                num_destinations = NUM_X * NUM_Y
                reverse = straight & 1  # LSB
                num_bits = clog2(num_destinations)
                for _ in range(1, num_bits):
                    reverse <<= 1
                    straight >>= 1
                    reverse |= (straight & 1)  # LSB
                ext_addr = (reverse % NUM_X + 1, reverse // NUM_X + 1)
            elif args.traffic_type == "bit_rotation":
                source = x-1 + (y-1) * NUM_X
                num_destinations = NUM_X * NUM_Y
                if source % 2 == 0:
                    ext = source // 2
                else:  # (source % 2 == 1)
                    ext = (source // 2) + (num_destinations // 2)
                ext_addr = (ext % NUM_X + 1, ext // NUM_X + 1)
            elif args.traffic_type == "neighbor":
                ext_addr = (x % NUM_X + 1, y)
            elif args.traffic_type == "shuffle":
                source = x-1 + (y-1) * NUM_X
                num_destinations = NUM_X * NUM_Y
                if source < num_destinations // 2:
                    ext = source * 2
                else: ext = (source * 2) - num_destinations + 1
                ext_addr = (ext % NUM_X + 1, ext // NUM_X + 1)
            elif args.traffic_type == "transpose":
                dest_x = y
                dest_y = x
                ext_addr = (dest_x, dest_y)
            elif args.traffic_type == "tornado":
                dest_x = (x-1 + math.ceil(NUM_X / 2) - 1) % NUM_X + 1
                ext_addr = (dest_x, y)
            elif args.traffic_type == "single_dest_boundary":
                ext_addr = (0, NUM_Y//2)
            elif args.traffic_type == "single_dest_center":
                ext_addr = (NUM_X//2, NUM_Y//2)
            else:
                raise ValueError(f"Unknown traffic type: {args.traffic_type}")
            src_addr = ext_addr if args.rw == "read" else local_addr
            dst_addr = local_addr if args.rw == "read" else ext_addr
            jobs.append((src_addr, dst_addr))
    return jobs

IMG_BORDER = 30
GRID_SIZE_X = IMG_WIDTH - 2*IMG_BORDER
GRID_SIZE_Y = IMG_HEIGHT - 2*IMG_BORDER
def get_position(x, y):
    """Get the image coords of a point in the mesh"""
    # input x,y is from 0,0 to NUM_X+1, NUM_Y+1
    # output is in image coords
    return (x*GRID_SIZE_X/(NUM_X+1)+IMG_BORDER, y*GRID_SIZE_Y/(NUM_Y+1)+IMG_BORDER)


def visualize_traffic_gif():
    """generate gif showing the traffic"""
    # pylint: disable=too-many-locals, consider-using-in, too-many-boolean-expressions
    # Make and save a drawing for each frame
    filename_list = [os.path.join(args.out_dir, 'temp' + str(n) + '.png')
                         for n in range(NUM_FRAMES)]
    # get the jobs
    jobs = gen_mesh_traffic()

    for frame in range(NUM_FRAMES):
        # initialize surface
        surf = pg.Surface((IMG_WIDTH,IMG_HEIGHT))
        surf.fill((255,255,255))
        # draw the mesh
        for x in range(NUM_X+2):
            for y in range(NUM_Y+2):
                line_color = (100,100,100)
                if x != NUM_X+1 and y != 0 and y != NUM_Y+1:
                    pg.draw.line(surf, line_color, get_position(x,y), get_position(x+1,y), 1)
                if y != NUM_Y+1 and x != 0 and x != NUM_X+1 :
                    pg.draw.line(surf, line_color, get_position(x,y), get_position(x,y+1), 1)
        for x in range(NUM_X+2):
            for y in range(NUM_Y+2):
                node_color = (0,0,0)
                if x == 0 and (y == 0 or y == NUM_Y+1) or x == NUM_X+1 and (y == 0 or y == NUM_Y+1):
                    continue
                if x == 0 or x == NUM_X+1 or y == 0 or y == NUM_Y+1:
                    node_color = (150,150,150)
                pg.draw.circle(surf, node_color, get_position(x,y), 10)

        # for each job calculate current position of circle to be drawn and draw it
        for job in jobs:
            factor = frame / NUM_FRAMES # 0 to 1
            factor = factor * factor * (3 - 2 * factor) # smoothstep
            # factor = factor * factor * factor * (10 + factor * (6 * factor - 15)) # smootherstep
            if job[0][0] == job[1][0] and job[0][1] == job[1][1]:
                continue
            coord = (job[1][0] * factor + job[0][0] * (1-factor),
                     job[1][1] * factor + job[0][1] * (1-factor))
            pg.draw.circle(surf, (255,0,0), get_position(coord[0], coord[1]), 4)
        pg.image.save(surf, filename_list[frame])

    seconds_per_frame = ANIMATION_LENGTH_SECONDS / NUM_FRAMES
    frame_delay = str(int(seconds_per_frame * 100))
    output_gif_filename = os.path.join(args.out_dir, args.traffic_type +'.gif')
    command_list = ['convert', '-delay', frame_delay, '-loop', '0'] + \
                    filename_list + [ output_gif_filename ]
    # Use the "convert" command (part of ImageMagick) to build the animation
    subprocess.call(command_list)
    # Earlier, we saved an image file for each frame of the animation. Now
    # that the animation is assembled, we can delete those files
    for filename in filename_list:
        os.remove(filename)

def visualize_traffic_image():
    """generate still image showing the traffic"""
    # pylint: disable=too-many-locals, c-extension-no-member, too-many-boolean-expressions, consider-using-in
    # get the jobs
    jobs = gen_mesh_traffic()
    # initialize surface
    surf = pg.Surface((IMG_WIDTH,IMG_HEIGHT))
    surf.fill((255,255,255))
    # draw the mesh
    for x in range(NUM_X+2):
        for y in range(NUM_Y+2):
            line_color = (100,100,100)
            if x != NUM_X+1 and y != 0 and y != NUM_Y+1:
                pg.draw.line(surf, line_color, get_position(x,y), get_position(x+1,y), 1)
            if y != NUM_Y+1 and x != 0 and x != NUM_X+1 :
                pg.draw.line(surf, line_color, get_position(x,y), get_position(x,y+1), 1)
    for x in range(NUM_X+2):
        for y in range(NUM_Y+2):
            node_color = (0,0,0)
            if x == 0 and (y == 0 or y == NUM_Y+1) or x == NUM_X+1 and (y == 0 or y == NUM_Y+1):
                continue
            if x == 0 or x == NUM_X+1 or y == 0 or y == NUM_Y+1:
                node_color = (150,150,150)
            pg.draw.circle(surf, node_color, get_position(x,y), 10)
    #arrow parameterd
    # minangle = 0, mindist = 1
    maxangle = math.pi/7 # at maxdist
    maxdist = math.sqrt(NUM_X**2 + NUM_Y**2)
    arrow_color = (255,0,0)
    arrow_tip_angle = math.pi/6
    arrow_tip_length = 7
    # for each job draw a arrow
    for job in jobs:
        if job[0][0] == job[1][0] and job[0][1] == job[1][1]:
            continue
        dist = math.sqrt((job[1][0] - job[0][0])**2 + (job[1][1] - job[0][1])**2)
        # starting and ending angle of arrow (as measured from connecting line)
        angle = (dist-1)*maxangle/(maxdist-1)
        line_direction = (job[1][0]-job[0][0], job[1][1]-job[0][1])
        line_angle = math.atan2(line_direction[1], line_direction[0])
        third_point_distance = dist/2/math.cos(angle)
        mid_point = get_position(job[0][0] + third_point_distance*math.cos(line_angle+angle),
                    job[0][1] + third_point_distance*math.sin(line_angle+angle))
        first_point = (get_position(job[0][0], job[0][1])[0]+math.cos(angle+line_angle)*10,
                      get_position(job[0][0], job[0][1])[1]+math.sin(angle+line_angle)*10)
        last_point = (get_position(job[1][0], job[1][1])[0]+math.cos(math.pi-angle+line_angle)*10,
                      get_position(job[1][0], job[1][1])[1]+math.sin(math.pi-angle+line_angle)*10)
        if dist==1:
            pg.draw.line(surf, arrow_color, first_point, last_point, 1)
        else:
            pygame.gfxdraw.bezier(surf, (first_point,
                                 mid_point,
                                 last_point),
                                 20, arrow_color)
        # draw arrow head: last_point is tip, angle is arrow_tip_angle
        pg.draw.polygon(surf, arrow_color, [last_point,
                (last_point[0] - arrow_tip_length*math.cos(-arrow_tip_angle+line_angle-angle),
                last_point[1] - arrow_tip_length*math.sin(-arrow_tip_angle+line_angle-angle)),
                (last_point[0] - arrow_tip_length*math.cos(arrow_tip_angle+line_angle-angle),
                last_point[1] - arrow_tip_length*math.sin(arrow_tip_angle+line_angle-angle))])
    output_filename = os.path.join(args.out_dir, args.traffic_type +'.png')
    pg.image.save(surf, output_filename)


def visualize_traffic():
    """visualize traffic"""
    if args.gif:
        visualize_traffic_gif()
    else:
        visualize_traffic_image()


def main():
    """Main function."""
    if not os.path.exists(args.out_dir):
        os.makedirs(args.out_dir)
    if args.traffic_type == "all":
        print("Visualizing all traffic types")
        traffic_types = ["neighbor", "random", "bit_complement", "bit_reverse",
                         "bit_rotation", "shuffle", "transpose", "tornado", "hbm",
                         "onehop", "single_dest_boundary", "single_dest_center"]
        for traffic_type in traffic_types:
            args.traffic_type = traffic_type
            visualize_traffic()
    else:
        visualize_traffic()
if __name__ == "__main__":
    main()
