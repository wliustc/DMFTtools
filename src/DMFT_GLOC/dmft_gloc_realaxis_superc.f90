subroutine dmft_get_gloc_realaxis_superc_main(Hk,Wtk,Greal,Sreal,hk_symm)
  complex(8),dimension(:,:,:,:),intent(in)        :: Hk        ![2][Nspin*Norb][Nspin*Norb][Nk]
  real(8),dimension(size(Hk,4)),intent(in)        :: Wtk       ![Nk]
  complex(8),dimension(:,:,:,:,:,:),intent(in)    :: Sreal     ![2][Nspin][Nspin][Norb][Norb][Lreal]
  complex(8),dimension(:,:,:,:,:,:),intent(inout) :: Greal     !as Sreal
  logical,dimension(size(Hk,4)),optional          :: hk_symm   ![Nk]
  logical,dimension(size(Hk,4))                   :: hk_symm_  ![Nk]
  !allocatable arrays
  complex(8),dimension(:,:,:,:,:,:),allocatable   :: Gkreal    !as Sreal
  complex(8),dimension(:,:,:,:,:),allocatable     :: zeta_real ![2][2][Nspin*Norb][Nspin*Norb][Lreal]
  !
  real(8)                                         :: beta
  real(8)                                         :: xmu,eps
  real(8)                                         :: wini,wfin  
  !
  !Retrieve parameters:
  call get_ctrl_var(beta,"BETA")
  call get_ctrl_var(xmu,"XMU")
  call get_ctrl_var(wini,"WINI")
  call get_ctrl_var(wfin,"WFIN")
  call get_ctrl_var(eps,"EPS")
  !
  hk_symm_=.false.;if(present(hk_symm)) hk_symm_=hk_symm
  !
  Nspin = size(Sreal,2)
  Norb  = size(Sreal,4)
  Lreal = size(Sreal,6)
  Lk    = size(Hk,4)
  Nso   = Nspin*Norb
  !Testing part:
  call assert_shape(Hk,[2,Nso,Nso,Lk],'dmft_get_gloc_realaxis_superc_main',"Hk")
  call assert_shape(Sreal,[2,Nspin,Nspin,Norb,Norb,Lreal],'dmft_get_gloc_realaxis_superc_main',"Sreal")
  call assert_shape(Greal,[2,Nspin,Nspin,Norb,Norb,Lreal],'dmft_get_gloc_realaxis_superc_main',"Greal")
  !
  allocate(Gkreal(2,Nspin,Nspin,Norb,Norb,Lreal))
  allocate(zeta_real(2,2,Nso,Nso,Lreal))
  if(allocated(wr))deallocate(wr);allocate(wr(Lreal))
  wr = linspace(wini,wfin,Lreal)
  !
  do i=1,Lreal
     zeta_real(1,1,:,:,i) = (dcmplx(wr(i),eps)+ xmu)*eye(Nso)                - &
          nn2so_reshape(Sreal(1,:,:,:,:,i),Nspin,Norb)
     zeta_real(1,2,:,:,i) =                                                  - &
          nn2so_reshape(Sreal(2,:,:,:,:,i),Nspin,Norb)
     zeta_real(2,1,:,:,i) =                                                  - &
          nn2so_reshape(Sreal(2,:,:,:,:,i),Nspin,Norb)
     zeta_real(2,2,:,:,i) = -conjg( dcmplx(wr(Lreal+1-i),eps)+xmu )*eye(Nso) + &
          conjg( nn2so_reshape(Sreal(1,:,:,:,:,Lreal+1-i),Nspin,Norb) )
  enddo
  !
  !invert (Z-Hk) for each k-point
  write(*,"(A)")"Get local Realaxis Superc Green's function (no print)"
  call start_timer
  Greal=zero
  do ik=1,Lk
     call invert_gk_superc(zeta_real,Hk(:,:,:,ik),hk_symm_(ik),Gkreal)
     Greal = Greal + Gkreal*Wtk(ik)
     call eta(ik,Lk)
  end do
  call stop_timer
end subroutine dmft_get_gloc_realaxis_superc_main


subroutine dmft_get_gloc_realaxis_superc_dos(Ebands,Dbands,Hloc,Greal,Sreal)
  real(8),dimension(:,:),intent(in)                                     :: Ebands    ![Nspin*Norb][Lk]
  real(8),dimension(size(Ebands,1),size(Ebands,2)),intent(in)           :: Dbands    ![Nspin*Norb][Lk]
  real(8),dimension(size(Ebands,1)),intent(in)                          :: Hloc      ![Nspin*Norb]
  complex(8),dimension(:,:,:,:,:,:),intent(in)                          :: Sreal     ![2][Nspin][Nspin][Norb][Norb][Lreal]
  complex(8),dimension(:,:,:,:,:,:),intent(inout)                       :: Greal     !as Sreal
  ! arrays
  complex(8),dimension(2,2,size(Ebands,1),size(Ebands,1),size(Sreal,6)) :: zeta_real ![2][2][Nspin*Norb][Nspin*Norb][Lreal]
  complex(8),dimension(2*size(Ebands,1),2*size(Ebands,1))               :: Gmatrix
  !
  real(8)                                                               :: beta
  real(8)                                                               :: xmu,wini,wfin,eps    
  !
  !Retrieve parameters:
  call get_ctrl_var(beta,"BETA")
  call get_ctrl_var(xmu,"XMU")
  call get_ctrl_var(wini,"WINI")
  call get_ctrl_var(wfin,"WFIN")
  call get_ctrl_var(eps,"EPS")
  !
  Nspin = size(Sreal,2)
  Norb  = size(Sreal,4)
  Lreal = size(Sreal,6)
  Lk    = size(Ebands,2)
  Nso   = Nspin*Norb
  !Testing part:
  call assert_shape(Ebands,[Nso,Lk],'dmft_get_gloc_realaxis_superc_dos',"Ebands")
  call assert_shape(Sreal,[2,Nspin,Nspin,Norb,Norb,Lreal],'dmft_get_gloc_realaxis_superc_main',"Sreal")
  call assert_shape(Greal,[2,Nspin,Nspin,Norb,Norb,Lreal],'dmft_get_gloc_realaxis_superc_main',"Greal")
  !

  if(allocated(wr))deallocate(wr);allocate(wr(Lreal))
  wr = linspace(wini,wfin,Lreal)
  !
  do i=1,Lreal
     zeta_real(1,1,:,:,i) = (dcmplx(wr(i),eps)+ xmu)*eye(Nso) - diag(Hloc)   - &
          nn2so_reshape(Sreal(1,:,:,:,:,i),Nspin,Norb)
     zeta_real(1,2,:,:,i) =                                                  - &
          nn2so_reshape(Sreal(2,:,:,:,:,i),Nspin,Norb)
     zeta_real(2,1,:,:,i) =                                                  - &
          nn2so_reshape(Sreal(2,:,:,:,:,i),Nspin,Norb)
     zeta_real(2,2,:,:,i) = -conjg( dcmplx(wr(Lreal+1-i),eps)+xmu )*eye(Nso) + diag(Hloc) + &
          conjg( nn2so_reshape(Sreal(1,:,:,:,:,Lreal+1-i),Nspin,Norb) )
  enddo
  !
  !invert (Z-Hk) for each k-point
  write(*,"(A)")"Get local Realaxis Superc Green's function (no print)"
  call start_timer
  Greal=zero
  do ik=1,Lk
     !
     do i=1,Lreal
        Gmatrix  = zero
        Gmatrix(1:Nso,1:Nso)             = zeta_real(1,1,:,:,i) - diag(Ebands(:,ik))
        Gmatrix(1:Nso,Nso+1:2*Nso)       = zeta_real(1,2,:,:,i)
        Gmatrix(Nso+1:2*Nso,1:Nso)       = zeta_real(2,1,:,:,i)
        Gmatrix(Nso+1:2*Nso,Nso+1:2*Nso) = zeta_real(2,2,:,:,i) + diag(Ebands(:,ik))
        !
        call inv(Gmatrix)  ! PAY ATTENTION HERE: it is not guaranteed that Gloc is a symmetric matrix
        !
        do ispin=1,Nspin
           do iorb=1,Norb
              io = iorb + (ispin-1)*Norb
              Greal(1,ispin,ispin,iorb,iorb,i) = Greal(1,ispin,ispin,iorb,iorb,i) + Gmatrix(io,io)*Dbands(io,ik)
              Greal(2,ispin,ispin,iorb,iorb,i) = Greal(2,ispin,ispin,iorb,iorb,i) + Gmatrix(io,Nso+io)*Dbands(io,ik)
           enddo
        enddo
        !
     enddo
     !
     call eta(ik,Lk)
  enddo
  call stop_timer
end subroutine dmft_get_gloc_realaxis_superc_dos





subroutine dmft_get_gloc_realaxis_superc_ineq(Hk,Wtk,Greal,Sreal,hk_symm)
  complex(8),dimension(:,:,:,:),intent(in)          :: Hk        ![2][Nlat*Nspin*Norb][Nlat*Nspin*Norb][Nk]
  real(8),dimension(size(Hk,4)),intent(in)          :: Wtk       ![Nk]
  complex(8),dimension(:,:,:,:,:,:,:),intent(in)    :: Sreal     ![2][Nlat][Nspin][Nspin][Norb][Norb][Lreal]
  complex(8),dimension(:,:,:,:,:,:,:),intent(inout) :: Greal     !as Sreal
  logical,dimension(size(Hk,4)),optional            :: hk_symm   ![Nk]
  logical,dimension(size(Hk,4))                     :: hk_symm_  ![Nk]
  !allocatable arrays
  complex(8),dimension(:,:,:,:,:,:,:),allocatable   :: Gkreal    !as Sreal
  complex(8),dimension(:,:,:,:,:,:),allocatable     :: zeta_real ![2][2][Nlat][Nspin*Norb][Nspin*Norb][Lreal]
  !
  real(8)                                           :: beta
  real(8)                                           :: xmu,eps
  real(8)                                           :: wini,wfin  
  !
  !Retrieve parameters:
  call get_ctrl_var(beta,"BETA")
  call get_ctrl_var(xmu,"XMU")
  call get_ctrl_var(wini,"WINI")
  call get_ctrl_var(wfin,"WFIN")
  call get_ctrl_var(eps,"EPS")
  !
  hk_symm_=.false.;if(present(hk_symm)) hk_symm_=hk_symm
  !
  Nlat  = size(Sreal,2)
  Nspin = size(Sreal,3)
  Norb  = size(Sreal,5)
  Lreal = size(Sreal,7)
  Lk    = size(Hk,4)
  Nso   = Nspin*Norb
  Nlso  = Nlat*Nspin*Norb
  !Testing part:
  call assert_shape(Hk,[2,Nlso,Nlso,Lk],'dmft_get_gloc_realaxis_superc_ineq',"Hk")
  call assert_shape(Sreal,[2,Nlat,Nspin,Nspin,Norb,Norb,Lreal],'dmft_get_gloc_realaxis_superc_ineq_main',"Sreal")
  call assert_shape(Greal,[2,Nlat,Nspin,Nspin,Norb,Norb,Lreal],'dmft_get_gloc_realaxis_superc_ineq_main',"Greal")
  !
  write(*,"(A)")"Get local Realaxis Superc Green's function (no print)"
  !
  allocate(Gkreal(2,Nlat,Nspin,Nspin,Norb,Norb,Lreal))
  allocate(zeta_real(2,2,Nlat,Nso,Nso,Lreal))
  if(allocated(wr))deallocate(wr);allocate(wr(Lreal))
  wr = linspace(wini,wfin,Lreal)
  !
  do ilat=1,Nlat
     !SYMMETRIES in real-frequencies   [assuming a real order parameter]
     !G22(w)  = -[G11[-w]]*
     !G21(w)  =   G12[w]   
     do i=1,Lreal
        zeta_real(1,1,ilat,:,:,i) = (dcmplx(wr(i),eps)+ xmu)*eye(Nso)                - &
             nn2so_reshape(Sreal(1,ilat,:,:,:,:,i),Nspin,Norb)
        zeta_real(1,2,ilat,:,:,i) =                                                  - &
             nn2so_reshape(Sreal(2,ilat,:,:,:,:,i),Nspin,Norb)
        zeta_real(2,1,ilat,:,:,i) =                                                  - &
             nn2so_reshape(Sreal(2,ilat,:,:,:,:,i),Nspin,Norb)
        zeta_real(2,2,ilat,:,:,i) = -conjg( dcmplx(wr(Lreal+1-i),eps)+xmu )*eye(Nso) + &
             conjg( nn2so_reshape(Sreal(1,ilat,:,:,:,:,Lreal+1-i),Nspin,Norb) )
     enddo
  enddo
  !
  call start_timer
  Greal=zero
  do ik=1,Lk
     call invert_gk_superc_ineq(zeta_real,Hk(:,:,:,ik),hk_symm_(ik),Gkreal)
     Greal = Greal + Gkreal*Wtk(ik)
     call eta(ik,Lk)
  end do
  call stop_timer
end subroutine dmft_get_gloc_realaxis_superc_ineq


subroutine dmft_get_gloc_realaxis_superc_gij(Hk,Wtk,Greal,Freal,Sreal,hk_symm)
  complex(8),dimension(:,:,:,:)                       :: Hk              ![2][Nlat*Norb*Nspin][Nlat*Norb*Nspin][Nk]
  real(8)                                           :: Wtk(size(Hk,4)) ![Nk]
  complex(8),intent(inout),dimension(:,:,:,:,:,:,:) :: Greal           ![Nlat][Nlat][Nspin][Nspin][Norb][Norb][Lreal]
  complex(8),intent(inout),dimension(:,:,:,:,:,:,:) :: Freal           ![Nlat][Nlat][Nspin][Nspin][Norb][Norb][Lreal]
  complex(8),intent(inout),dimension(:,:,:,:,:,:,:) :: Sreal           ![2][Nlat][Nspin][Nspin][Norb][Norb][Lreal]
  logical,optional                                  :: hk_symm(size(Hk,4))
  logical                                           :: hk_symm_(size(Hk,4))
  !
  complex(8),dimension(:,:,:,:,:,:),allocatable     :: zeta_real       ![2][2][Nlat][Nspin*Norb][Nspin*Norb][Lreal]
  complex(8),dimension(:,:,:,:,:,:,:),allocatable   :: Gkreal          ![Nlat][Nlat][Nspin][Nspin][Norb][Norb][Lreal]
  complex(8),dimension(:,:,:,:,:,:,:),allocatable   :: Fkreal          ![Nlat][Nlat][Nspin][Nspin][Norb][Norb][Lreal]
  integer                                           :: ik,Lk,Nlso,Nlat,Nspin,Nso,ilat,jlat,iorb,jorb,ispin,jspin,io,jo,js,Lreal
  real(8)                                           :: beta
  real(8)                                           :: xmu,eps
  real(8)                                           :: wini,wfin  
  !
  !
  !Retrieve parameters:
  call get_ctrl_var(beta,"BETA")
  call get_ctrl_var(xmu,"XMU")
  call get_ctrl_var(wini,"WINI")
  call get_ctrl_var(wfin,"WFIN")
  call get_ctrl_var(eps,"EPS")
  !
  Nlat  = size(Sreal,2)
  Nspin = size(Sreal,3)
  Norb  = size(Sreal,5)
  Lreal = size(Sreal,7)
  Lk    = size(Hk,4)
  Nso   = Nspin*Norb
  Nlso  = Nlat*Nspin*Norb
  !Testing part:
  call assert_shape(Hk,[2,Nlso,Nlso,Lk],'dmft_get_gloc_realaxis_superc_gij_main',"Hk")
  call assert_shape(Sreal,[2,Nlat,Nspin,Nspin,Norb,Norb,Lreal],'dmft_get_gloc_realaxis_superc_gij_main',"Sreal")
  call assert_shape(Greal,[Nlat,Nlat,Nspin,Nspin,Norb,Norb,Lreal],'dmft_get_gloc_realaxis_superc_gij_main',"Greal")
  call assert_shape(Freal,[Nlat,Nlat,Nspin,Nspin,Norb,Norb,Lreal],'dmft_get_gloc_realaxis_superc_gij_main',"Freal")
  !
  hk_symm_=.false.;if(present(hk_symm)) hk_symm_=hk_symm
  !
  write(*,"(A)")"Get full Green's function (no print)"
  !
  allocate(Gkreal(Nlat,Nlat,Nspin,Nspin,Norb,Norb,Lreal));Gkreal=zero
  allocate(Fkreal(Nlat,Nlat,Nspin,Nspin,Norb,Norb,Lreal));Fkreal=zero
  allocate(zeta_real(2,2,Nlat,Nso,Nso,Lreal));zeta_real=zero
  if(allocated(wr))deallocate(wr);allocate(wr(Lreal))
  wr = linspace(wini,wfin,Lreal)
  zeta_real=zero
  !SYMMETRIES in real-frequencies   [assuming a real order parameter]
  !G22(w)  = -[G11[-w]]*
  !G21(w)  =   G12[w]    
  do ilat=1,Nlat
     do ispin=1,Nspin
        do iorb=1,Norb
           io = iorb + (ispin-1)*Norb
           js = iorb + (ispin-1)*Norb + (ilat-1)*Norb*Nspin
           zeta_real(1,1,ilat,io,io,:) = dcmplx(wr(:),eps) + xmu
           zeta_real(2,2,ilat,io,io,:) = -conjg( dcmplx(wr(Lreal:1:-1),eps) + xmu )
        enddo
     enddo
     do ispin=1,Nspin
        do jspin=1,Nspin
           do iorb=1,Norb
              do jorb=1,Norb
                 io = iorb + (ispin-1)*Norb
                 jo = jorb + (jspin-1)*Norb
                 zeta_real(1,1,ilat,io,jo,:) = zeta_real(1,1,ilat,io,jo,:) - &
                      Sreal(1,ilat,ispin,jspin,iorb,jorb,:)
                 zeta_real(1,2,ilat,io,jo,:) = zeta_real(1,2,ilat,io,jo,:) - &
                      Sreal(2,ilat,ispin,jspin,iorb,jorb,:)
                 zeta_real(2,1,ilat,io,jo,:) = zeta_real(2,1,ilat,io,jo,:) - &
                      Sreal(2,ilat,ispin,jspin,iorb,jorb,:)
                 zeta_real(2,2,ilat,io,jo,:) = zeta_real(2,2,ilat,io,jo,:) + &
                      conjg( Sreal(1,ilat,ispin,jspin,iorb,jorb,Lreal:1:-1) )
              enddo
           enddo
        enddo
     enddo
  enddo
  !
  call start_timer
  Greal=zero
  do ik=1,Lk
     call invert_gk_superc_gij(zeta_real,Hk(:,:,:,ik),hk_symm_(ik),Gkreal,Fkreal)
     Greal = Greal + Gkreal*Wtk(ik)
     Freal = Freal + Fkreal*Wtk(ik)
     call eta(ik,Lk)
  end do
  call stop_timer
end subroutine dmft_get_gloc_realaxis_superc_gij



