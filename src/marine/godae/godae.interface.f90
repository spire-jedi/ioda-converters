module godae_c_interface_mod

  use iso_c_binding

  implicit none

  private
  public :: open_c
  public :: close_c
  public :: read_metadata_c

contains

!Private
function c_f_string(c_str) result(f_str)
  character(kind=c_char,len=1), intent(in) :: c_str(*)
  character(len=:), allocatable :: f_str
  integer :: nchars

  nchars = 1
  do while (c_str(nchars) /= c_null_char)
      nchars = nchars + 1
  end do
  nchars = nchars - 1

  allocate(character(len=nchars) :: f_str)
  f_str = transfer(c_str(1:nchars), f_str)
end function c_f_string


subroutine copy_f_c_str(f_str, c_str, c_str_len)
  character(len=*), target, intent(in) :: f_str
  character(kind=c_char, len=1), intent(inout) :: c_str(*)
  integer, intent(in) :: c_str_len
  integer :: max_str_len

  if (c_str_len /= 0) then
    max_str_len = min(c_str_len - 1, len_trim(f_str))
    c_str(1)(1:max_str_len) = f_str(1:max_str_len)
    c_str(1)(max_str_len:max_str_len) = c_null_char
  end if
end subroutine copy_f_c_str


!Public
subroutine open_c(lunit, filepath) bind(C, name='open_f')
  integer(c_int), value, intent(in) :: lunit
  character(kind=c_char, len=1) :: filepath

  open(lunit, file=c_f_string(filepath), status='old', form='unformatted')
end subroutine open_c


subroutine close_c(lunit) bind(C, name='close_f')
  integer(c_int), value, intent(in) :: lunit

  close(unit=lunit)
end subroutine close_c


subroutine read_metadata_c(lunit, n_obs, n_lvl, n_vrsn) bind(C, name='read_metadata_f')
  integer(c_int), value, intent(in)  :: lunit
  integer(c_int),        intent(out) :: n_obs, n_lvl, n_vrsn

  call read_metadata(lunit, n_obs, n_lvl, n_vrsn)
end subroutine read_metadata_c


!subroutine ufbrep_c(bufr_unit, c_data, dim_1, dim_2, iret, table_b_mnemonic) bind(C, name='ufbrep_f')
!  integer(c_int), value, intent(in) :: bufr_unit
!  type(c_ptr), intent(inout) :: c_data
!  integer(c_int), value, intent(in) :: dim_1, dim_2
!  integer(c_int), intent(out) :: iret
!  character(kind=c_char, len=1), intent(in) :: table_b_mnemonic
!  real, pointer :: f_data
!
!  call c_f_pointer(c_data, f_data)
!  call ufbrep(bufr_unit, f_data, dim_1, dim_2, iret, c_f_string(table_b_mnemonic))
!end subroutine ufbrep_c


end module godae_c_interface_mod
