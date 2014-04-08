!> @ingroup DerivedType
!> @{
!> @defgroup Data_Type_Command_Line_ArgumentDerivedType Data_Type_Command_Line_Argument
!> @}

!> @ingroup Interface
!> @{
!> @defgroup Data_Type_Command_Line_ArgumentInterface Data_Type_Command_Line_Argument
!> Module definition of Type_Command_Line_Argument
!> @}

!> @ingroup PrivateProcedure
!> @{
!> @defgroup Data_Type_Command_Line_ArgumentPrivateProcedure Data_Type_Command_Line_Argument
!> Module definition of Type_Command_Line_Argument
!> @}

!> @ingroup PublicProcedure
!> @{
!> @defgroup Data_Type_Command_Line_ArgumentPublicProcedure Data_Type_Command_Line_Argument
!> Module definition of Type_Command_Line_Argument
!> @}

!> @brief This module contains the definition of Type_Command_Line_Argument and its procedures.
!> Type_Command_Line_Argument (CLA) is a derived type containing the useful data for handling command line arguments in order to
!> easy implement flexible a Command Line Interface (CLI).
!> @note Presently there is no support for positional CLAs, but only for named ones.
!> @note Presently there is no support for multiple valued CLAs, but only for single valued ones (or without any value, i.e. logical
!> CLA).
!> @todo Add support for positional CLAs.
!> @todo Add support for multiple valued (list of values) CLAs.
module Data_Type_Command_Line_Argument
!-----------------------------------------------------------------------------------------------------------------------------------
USE IR_Precision ! Integers and reals precision definition.
USE Lib_IO_Misc  ! Procedures for IO and strings operations.
!-----------------------------------------------------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------------------------------------------------
implicit none
private
public:: action_store,action_store_true,action_store_false
public:: cla_init
!-----------------------------------------------------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------------------------------------------------
character(5),  parameter:: action_store       = 'STORE'       !< CLA that stores a value associated to its switch.
character(10), parameter:: action_store_true  = 'STORE_TRUE'  !< CLA that stores .true. without the necessity of a value.
character(11), parameter:: action_store_false = 'STORE_FALSE' !< CLA that stores .false. without the necessity of a value.
!> Derived type containing the useful data for handling command line arguments in order to easy implement flexible a Command Line
!> Interface (CLI).
!> @note If not otherwise declared the action on CLA value is set to "store" a value that must be passed after the switch name.
!> @ingroup Data_Type_Command_Line_ArgumentDerivedType
type, public:: Type_Command_Line_Argument
  character(len=:), allocatable:: switch           !< Switch name.
  character(len=:), allocatable:: switch_ab        !< Abbreviated switch name.
  character(len=:), allocatable:: help             !< Help message describing the CLA.
  logical::                       required=.false. !< Flag for set required argument.
  logical::                       passed  =.false. !< Flag for checking if CLA has been passed to CLI.
  character(len=:), allocatable:: act              !< CLA value action.
  character(len=:), allocatable:: def              !< Default value.
  character(len=:), allocatable:: nargs            !< Number of arguments of CLA.
  character(len=:), allocatable:: val              !< CLA value.
  contains
    procedure:: free => free_self   ! Procedure for freeing dynamic memory.
    procedure:: init => init_self   ! Procedure for initializing CLA.
    procedure:: get  => get_self    ! Procedure for getting CLA value.
    procedure:: check => check_self ! Procedure for checking CLA data consistency.
    final::     finalize            ! Procedure for freeing dynamic memory when finalizing.
    ! operators overloading
    generic:: assignment(=) => assign_self
    ! private procedures
    procedure, pass(self1), private:: assign_self
endtype Type_Command_Line_Argument
!-----------------------------------------------------------------------------------------------------------------------------------
contains
  !> @ingroup Data_Type_Command_Line_ArgumentPrivateProcedure
  !> @{
  !> @brief Procedure for freeing dynamic memory.
  elemental subroutine free_self(cla)
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  class(Type_Command_Line_Argument), intent(INOUT):: cla !< CLA data.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (allocated( cla%switch   )) deallocate(cla%switch   )
  if (allocated( cla%switch_ab)) deallocate(cla%switch_ab)
  if (allocated( cla%help     )) deallocate(cla%help     )
  if (allocated( cla%act      )) deallocate(cla%act      )
  if (allocated( cla%def      )) deallocate(cla%def      )
  if (allocated( cla%nargs    )) deallocate(cla%nargs    )
  if (allocated( cla%val      )) deallocate(cla%val      )
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine free_self

  !> @brief Procedure for freeing dynamic memory when finalizing.
  elemental subroutine finalize(cla)
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  type(Type_Command_Line_Argument), intent(INOUT):: cla !< CLA data.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  call cla%free
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine finalize

  !> @brief Procedure for initializing CLA.
  !> @note If not otherwise declared the action on CLA value is set to "store" a value that must be passed after the switch name.
  elemental subroutine init_self(cla,switch_ab,help,required,act,def,nargs,switch)
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  class(Type_Command_Line_Argument), intent(INOUT):: cla       !< CLA data.
  character(*), optional,            intent(IN)::    switch_ab !< Abbreviated switch name.
  character(*), optional,            intent(IN)::    help      !< Help message describing the CLA.
  logical,      optional,            intent(IN)::    required  !< Flag for set required argument.
  character(*), optional,            intent(IN)::    act       !< CLA value action.
  character(*), optional,            intent(IN)::    def       !< Default value.
  character(*), optional,            intent(IN)::    nargs     !< Number of arguments of CLA.
  character(*),                      intent(IN)::    switch    !< Switch name.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  cla%switch    = switch
  cla%switch_ab = switch                  ; if (present(switch_ab)) cla%switch_ab = switch_ab
  cla%help      = 'Undocumented argument' ; if (present(help     )) cla%help      = help
  cla%required  = .false.                 ; if (present(required )) cla%required  = required
  cla%act       = action_store            ; if (present(act      )) cla%act       = trim(adjustl(Upper_Case(act)))
                                            if (present(def      )) cla%def       = def
                                            if (present(nargs    )) cla%nargs     = nargs
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine init_self

  !> @brief Procedure for getting CLA value.
  !> @note For logical type CLA the value is directly read without any robust error trapping.
  subroutine get_self(cla,pref,val)
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  class(Type_Command_Line_Argument), intent(INOUT):: cla   !< CLA data.
  character(*), optional,            intent(IN)::    pref  !< Prefixing string.
  class(*),                          intent(INOUT):: val   !< CLA value.
  character(len=:), allocatable::                    prefd !< Prefixing string.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  prefd = '' ; if (present(pref)) prefd = pref
  if (((.not.cla%passed).and.cla%required).or.((.not.cla%passed).and.(.not.allocated(cla%def)))) then
    write(stderr,'(A)')prefd//' Error: CLA "'//trim(adjustl(cla%switch))//'" is required by CLI but it has not been passed!'
    return
  endif
  if (cla%act==action_store) then
    if (cla%passed) then
      select type(val)
#ifdef r16p
      type is(real(R16P))
        val = cton(str=trim(adjustl(cla%val)),knd=1._R16P)
#endif
      type is(real(R8P))
        val = cton(str=trim(adjustl(cla%val)),knd=1._R8P)
      type is(real(R4P))
        val = cton(str=trim(adjustl(cla%val)),knd=1._R4P)
      type is(integer(I8P))
        val = cton(str=trim(adjustl(cla%val)),knd=1_I8P)
      type is(integer(I4P))
        val = cton(str=trim(adjustl(cla%val)),knd=1_I4P)
      type is(integer(I2P))
        val = cton(str=trim(adjustl(cla%val)),knd=1_I2P)
      type is(integer(I1P))
        val = cton(str=trim(adjustl(cla%val)),knd=1_I1P)
      type is(logical)
        read(cla%val,*)val
      type is(character(*))
        val = cla%val
      endselect
    else
      select type(val)
#ifdef r16p
      type is(real(R16P))
        val = cton(str=trim(adjustl(cla%def)),knd=1._R16P)
#endif
      type is(real(R8P))
        val = cton(str=trim(adjustl(cla%def)),knd=1._R8P)
      type is(real(R4P))
        val = cton(str=trim(adjustl(cla%def)),knd=1._R4P)
      type is(integer(I8P))
        val = cton(str=trim(adjustl(cla%def)),knd=1_I8P)
      type is(integer(I4P))
        val = cton(str=trim(adjustl(cla%def)),knd=1_I4P)
      type is(integer(I2P))
        val = cton(str=trim(adjustl(cla%def)),knd=1_I2P)
      type is(integer(I1P))
        val = cton(str=trim(adjustl(cla%def)),knd=1_I1P)
      type is(logical)
        read(cla%def,*)val
      type is(character(*))
        val = cla%def
      endselect
    endif
  elseif (cla%act==action_store_true) then
    if (cla%passed) then
      select type(val)
      type is(logical)
        val = .true.
      endselect
    else
      select type(val)
      type is(logical)
        read(cla%def,*)val
      endselect
    endif
  elseif (cla%act==action_store_false) then
    if (cla%passed) then
      select type(val)
      type is(logical)
        val = .false.
      endselect
    else
      select type(val)
      type is(logical)
        read(cla%def,*)val
      endselect
    endif
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine get_self

  !> @brief Procedure for checking CLA data consistency.
  subroutine check_self(cla,pref,error)
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  class(Type_Command_Line_Argument), intent(IN)::  cla   !< CLA data.
  character(*), optional,            intent(IN)::  pref  !< Prefixing string.
  integer(I4P),                      intent(OUT):: error !< Error trapping flag.
  character(len=:), allocatable::                  prefd !< Prefixing string.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  error = 0
  if ((.not.cla%required).and.(.not.allocated(cla%def))) then
    error = 1
    prefd = '' ; if (present(pref)) prefd = pref
    write(stderr,'(A)')prefd//' Error: the CLA "'//cla%switch//'" is not set as "required" but no default value has been set!'
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine check_self

  ! Assignment (=)
  !> @brief Procedure for assignment between two selfs.
  elemental subroutine assign_self(self1,self2)
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  class(Type_Command_Line_Argument), intent(INOUT):: self1
  type(Type_Command_Line_Argument),  intent(IN)::    self2
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (allocated(self2%switch   )) self1%switch    =  self2%switch
  if (allocated(self2%switch_ab)) self1%switch_ab =  self2%switch_ab
  if (allocated(self2%help     )) self1%help      =  self2%help
  if (allocated(self2%act      )) self1%act       =  self2%act
  if (allocated(self2%def      )) self1%def       =  self2%def
  if (allocated(self2%nargs    )) self1%nargs     =  self2%nargs
  if (allocated(self2%val      )) self1%val       =  self2%val
                                  self1%required  =  self2%required
                                  self1%passed    =  self2%passed
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine assign_self
  !> @}

  !> @ingroup Data_Type_Command_Line_ArgumentPublicProcedure
  !> @{
  !> @brief Procedure for parsing Command Line Arguments by means of a previously initialized CLA list.
  !> @note This procedure should execute the identical statements of type bound procedure init_self.
  elemental function cla_init(switch_ab,help,required,act,def,nargs,switch) result(cla)
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  character(*), optional, intent(IN):: switch_ab !< Abbreviated switch name.
  character(*), optional, intent(IN):: help      !< Help message describing the CLA.
  logical,      optional, intent(IN):: required  !< Flag for set required argument.
  character(*), optional, intent(IN):: act       !< CLA value action.
  character(*), optional, intent(IN):: def       !< Default value.
  character(*), optional, intent(IN):: nargs     !< Number of arguments of CLA.
  character(*),           intent(IN):: switch    !< Switch name.
  type(Type_Command_Line_Argument)::   cla       !< CLA data.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  cla%switch    = switch
  cla%switch_ab = switch                  ; if (present(switch_ab)) cla%switch_ab = switch_ab
  cla%help      = 'Undocumented argument' ; if (present(help     )) cla%help      = help
  cla%required  = .false.                 ; if (present(required )) cla%required  = required
  cla%act       = action_store            ; if (present(act      )) cla%act       = trim(adjustl(Upper_Case(act)))
                                            if (present(def      )) cla%def       = def
                                            if (present(nargs    )) cla%nargs     = nargs
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction cla_init
  !> @}
endmodule Data_Type_Command_Line_Argument
