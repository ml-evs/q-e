!
! Copyright (C) 2001 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!
!-----------------------------------------------------------------------
subroutine compute_drhous (drhous, dbecsum, wgg, becq, alpq)
  !-----------------------------------------------------------------------
  !
  !    This routine computes the part of the change of the charge density
  !    which is due to the orthogonalization constraint on wavefunctions
  !
  !
#include"machine.h"

  use pwcom
  USE wavefunctions_module,  ONLY: evc
  USE io_files, ONLY: iunigk
  use parameters, only : DP
  use phcom
  implicit none
  !
  !     the dummy variables
  !

  complex(kind=DP) :: dbecsum (nhm * (nhm + 1) / 2, nat, nspin, 3 * nat) &
       , drhous (nrxxs, nspin, 3 * nat), becq (nkb, nbnd, nksq), &
       alpq (nkb, nbnd, 3, nksq)
  !output:the derivative of becsum
  ! output: add the orthogonality term
  ! input: the becp with psi_{k+q}
  ! input: the alphap with psi_{k+q}

  real(kind=DP) :: wgg (nbnd, nbnd, nksq)
  ! input: the weights

  integer :: ipert, mode, ik, ikq, ikk, is, ig, nu_i, ibnd, ios
  ! counter on the pertubations
  ! counter on the modes
  ! counter on k points
  ! the point k+q
  ! record for wfcs at k point
  ! counter on spin
  ! counter on g vectors
  ! counter on modes
  ! counter on the bands
  ! integer variable for I/O control

  real(kind=DP) :: weight
  ! the weight of the k point

  complex(kind=DP), allocatable :: evcr (:,:)
  ! the wavefunctions in real space

  if (.not.okvan) return

  call start_clock ('com_drhous')
  allocate (evcr( nrxxs , nbnd))    
  !
  drhous(:,:,:) = (0.d0, 0.d0)
  dbecsum (:,:,:,:) = (0.d0, 0.d0)

  if (nksq.gt.1) rewind (unit = iunigk)
  do ik = 1, nksq
     if (nksq.gt.1) then
        read (iunigk, err = 110, iostat = ios) npw, igk
110     call errore ('compute_drhous', 'reading igk', abs (ios) )
     endif
     if (lgamma) then
        ikk = ik
        ikq = ik
        npwq = npw
     else
        ikk = 2 * ik - 1
        ikq = ikk + 1
     endif
     weight = wk (ikk)

     if (lsda) current_spin = isk (ikk)
     if (.not.lgamma.and.nksq.gt.1) then
        read (iunigk, err = 210, iostat = ios) npwq, igkq
210     call errore ('compute_drhous', 'reading igkq', abs (ios) )
     endif
     !
     !   For each k point we construct the beta functions
     !
     call init_us_2 (npwq, igkq, xk (1, ikq), vkb)
     !
     !   Read the wavefunctions at k and transform to real space
     !

     call davcio (evc, lrwfc, iuwfc, ikk, - 1)
     evcr(:,:) = (0.d0, 0.d0)
     do ibnd = 1, nbnd
        do ig = 1, npw
           evcr (nls (igk (ig) ), ibnd) = evc (ig, ibnd)
        enddo
        call cft3s (evcr (1, ibnd), nr1s, nr2s, nr3s, nrx1s, nrx2s, nrx3s,+2)
     enddo
     !
     !   Read the wavefunctions at k+q
     !
     if (.not.lgamma.and.nksq.gt.1) call davcio (evq, lrwfc, iuwfc, ikq, -1)
     !
     !   And compute the contribution of this k point to the change of
     !   the charge density
     !
     do nu_i = 1, 3 * nat
        call incdrhous (drhous (1, current_spin, nu_i), weight, ik, &
             dbecsum (1, 1, current_spin, nu_i), evcr, wgg, becq, alpq, nu_i)
     enddo

  enddo

  deallocate(evcr)
  call stop_clock ('com_drhous')
  return

end subroutine compute_drhous
