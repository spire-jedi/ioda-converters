#============================================================================
# This file contains a dictionary for mapping BUFR message (subset) types
# to YAML files used to convert BUFR to IODA netCDF. It should be editted
# to add any needed message type.
#===========================================================================

YAML_FILES = {"NC005024":"satwnds_old_subset_template.yaml",
              "NC005025":"satwnds_old_subset_template.yaml",
              "NC005026":"satwnds_old_subset_template.yaml",
              "NC005030":"satwnds_new_subset_template.yaml",
              "NC005031":"satwnds_new_subset_template.yaml",
              "NC005032":"satwnds_new_subset_template.yaml",
              "NC005034":"satwnds_new_subset_template.yaml",
              "NC005039":"satwnds_new_subset_template.yaml",
              "NC005044":"satwnds_old_subset_template.yaml",
              "NC005045":"satwnds_old_subset_template.yaml",
              "NC005046":"satwnds_old_subset_template.yaml",
              "NC005064":"satwnds_old_subset_template.yaml",
              "NC005065":"satwnds_old_subset_template.yaml",
              "NC005066":"satwnds_old_subset_template.yaml",
              #"NC005070":"satwnds_new_subset_template.yaml",
              #"NC005071":"satwnds_new_subset_template.yaml",
              #"NC005080":"satwnds_new_subset_template.yaml",
              "NC005070":"satwnds_old_subset_template.yaml",
              "NC005071":"satwnds_old_subset_template.yaml",
              "NC005080":"satwnds_old_subset_template.yaml",
              "NC005091":"satwnds_new_subset_template.yaml",
              "NC012122":"scatterometer_winds.yaml"}
