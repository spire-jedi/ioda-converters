#!/usr/bin/env python3
#
# (C) Copyright 2020 NOAA/NWS/NCEP/EMC
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
#

import argparse
from datetime import datetime
import glob
import os
import pathlib
import re
import subprocess


# Define template file paths
EXE_DIR = pathlib.Path(__file__).parent.absolute()
TEMPLATE_PATH = os.path.join(EXE_DIR, 'ascat_winds_template.yaml')
ASCAT_TYPE = "ASCATW"


def _make_file_from_template(template_path, replacements, output_path):
    tag_re = re.compile(r'{{\s*(?P<key>\w+)\s*}}')

    lines = []
    with open(template_path, 'r') as template_file:
        for line in template_file.readlines():
            matches = tag_re.findall(line)
            for match_key in matches:
                if match_key in replacements:
                    line = tag_re.sub(replacements[match_key], line)
                else:
                    raise Exception(f'Unknown tag with key {match_key} in \
                                      {template_path}')
            lines.append(line)

    with open(output_path, 'w') as new_file:
        new_file.writelines(lines)


def _process_bufr_path(path):
    print(f'Running {path}.')

    yaml_template = TEMPLATE_PATH

    yaml_out_path = f'{ASCAT_TYPE}.yaml'
    _make_file_from_template(yaml_template,
                             {'obsdatain': ASCAT_TYPE,
                              'obsdataout': f'{ASCAT_TYPE}.nc'},
                             yaml_out_path)

    print(f'bufr2ioda.x {yaml_out_path}')
    subprocess.call(f'bufr2ioda.x {yaml_out_path}', shell=True)

    # Cleanup
    #os.remove(yaml_out_path)


def run(bufr_path):
    """
    Runs bufr2ioda on each one.
    :param bufr_path: Path to the Sat winds Bufr file.
    """

    def _set_up_working_dir():
        timestamp_str = datetime.now().strftime("%Y%m%d%H%M%S")
        working_dir = f'ascat_processing_{timestamp_str}'
        os.mkdir(working_dir)
        os.chdir(working_dir)

    def _clean_working_dir():
        allFiles = glob.glob("*")
        for path in allFiles:
            if not re.search("nc$", path):
                print("should delete ", path)
                #os.remove(path)

    input_path = os.path.realpath(bufr_path)

    _set_up_working_dir()

    # Split the input file
    subprocess.call(f'/scratch2/NCEPDEV/ovp/Jeffrey.Smith/SAT_WINDS4/build/utils/split_by_subset.x {input_path}', shell=True)

    # Process each subset bufr file.
    #bufr_paths = glob.glob('NC*')
    #bufr_paths = ["NC012122"]
    #bufr_paths = ["ASCATW"]
    _process_bufr_path(bufr_path)

    # Cleanup
    _clean_working_dir()


if __name__ == '__main__':
    DESCRIPTION = 'Runs bufr2ioda.x with the proper configuration.'

    parser = argparse.ArgumentParser(description=DESCRIPTION)
    parser.add_argument('file',
                        type=str,
                        help="ASCAT file")

    parser.add_argument('-t',
                        default=1,
                        type=int,
                        help="Number of concurrent instances of bufr2ioda.")

    args = parser.parse_args()

    start_time = datetime.now()
    run(args.file)
    print((datetime.now() - start_time).total_seconds())
