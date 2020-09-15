#ifndef MARINE_GODAE_INTERFACE_H_
#define MARINE_GODAE_INTERFACE_H_

/// Interface to Fortran ocn_obs_jedi routines
/*
 * The core of the ocn_obs_jedi is coded in Fortran.
 * Here we define the interfaces to the Fortran code.
 */

extern "C" {

  void open_f(int lunit, const char* filepath);
  void close_f(int lunit);
  void read_metadata_f(int lunit, int* n_obs, int* n_lvl, int* n_vrsn)
  // void ufbrep_f(int bufr_unit, void** c_data, int dim_1, int dim_2, int* iret, const char* table_b_mnemonic);

}  // extern C

#endif   // MARINE_GODAE_INTERFACE_H_
