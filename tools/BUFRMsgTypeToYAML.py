#============================================================================
# This file contains a dictionary for mapping BUFR message (subset) types
# to YAML files used to convert BUFR to IODA netCDF. It should be editted
# to add any needed message type.
#===========================================================================

YAML_FILES = {"NC005024":"bufr_satwnd_old_format.yaml",
              "NC005025":"bufr_satwnd_old_format.yaml",
              "NC005026":"bufr_satwnd_old_format.yaml",
              "NC005030":"bufr_satwnd_new_format.yaml",
              "NC005031":"bufr_satwnd_new_format.yaml",
              "NC005032":"bufr_satwnd_new_format.yaml",
              "NC005034":"bufr_satwnd_new_format.yaml",
              "NC005039":"bufr_satwnd_new_format.yaml",
              "NC005044":"bufr_satwnd_old_format.yaml",
              "NC005045":"bufr_satwnd_old_format.yaml",
              "NC005046":"bufr_satwnd_old_format.yaml",
              "NC005064":"bufr_satwnd_old_format.yaml",
              "NC005065":"bufr_satwnd_old_format.yaml",
              "NC005066":"bufr_satwnd_old_format.yaml",
              "NC005070":"bufr_satwnd_old78_format.yaml",
              "NC005071":"bufr_satwnd_old78_format.yaml",
              "NC005080":"bufr_satwnd_old78_format.yaml",
              "NC005070":"bufr_satwnd_old_format.yaml",
              "NC005071":"bufr_satwnd_old_format.yaml",
              "NC005080":"bufr_satwnd_old_format.yaml",
              "NC005091":"bufr_satwnd_new_format.yaml",
              #"NC012122":"ascat_winds_template.yaml",
              "ASCATW":"ascat_winds_template.yaml"}
