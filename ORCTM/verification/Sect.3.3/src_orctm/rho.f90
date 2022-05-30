      FUNCTION RHO(S,T,P)
!*********************************************************************
!
!
!     RRRRR   H    H   OOO
!     R    R  H    H  O   O
!     RRRRR   HHHHHH  O   O
!     R  RR   H    H  O   O
!     R   RR  H    H   OOO
!
!*****************************************************************
! WIRD FUER DEN REFERENZ-ZUSTAND VERWENDET
!++++++++++++++++++++++++++++++++++++++++++++++++++++
      DATA B0,B1,B2,B3,B4/8.24493E-1,-4.0899E-3,7.6438E-5,              &
     &-8.2467E-7,5.3875E-9/
      DATA C0,C1,C2/-5.72466E-3,1.0227E-4,-1.6546E-6/
      DATA D0/4.8314E-4/
      DATA A0,A1,A2,A3,A4,A5/999.842594,6.793952E-2,                    &
     &-9.095290E-3,1.001685E-4,-1.120083E-6,6.536332E-9/
      DATA F0,F1,F2,F3/54.6746,-0.603459,                               &
     &1.09987E-2,-6.1670E-5/
      DATA G0,G1,G2/7.944E-2,1.6483E-2,-5.3009E-4/
      DATA AI0,AI1,AI2/2.2838E-3,-1.0981E-5,-1.6078E-6/
      DATA AJ0/1.91075E-4/
      DATA AM0,AM1,AM2/-9.9348E-7,2.0816E-8,9.1697E-10/
      DATA E0,E1,E2,E3,E4/19652.21,148.4206,-2.327105,                  &
     &1.360477E-2,-5.155288E-5/
      DATA H0,H1,H2,H3/3.239908,1.43713E-3,                             &
     &1.16092E-4,-5.77905E-7/
      DATA AK0,AK1,AK2/8.50935E-5,-6.12293E-6,5.2787E-8/
      S3H=SQRT(S**3)
      RHOW=A0+T*(A1+T*(A2+T*(A3+T*(A4+T*A5))))
      AKW=E0+T*(E1+T*(E2+T*(E3+T*E4)))
      AW=H0+T*(H1+T*(H2+T*H3))
      BW=AK0+T*(AK1+T*AK2)
      B=BW+S*(AM0+T*(AM1+T*AM2))
      A=AW+S*(AI0+T*(AI1+AI2*T))+AJ0*S3H
      AKST0=AKW+S*(F0+T*(F1+T*(F2+T*F3)))+S3H*(G0+T*(G1+G2*T))
      AKSTP=AKST0+P*(A+B*P)
      RHST0=RHOW+S*(B0+T*(B1+T*(B2+T*(B3+T*B4))))+D0*S**2               &
     &+S3H*(C0+T*(C1+C2*T))
      RHO=RHST0/(1.-P/AKSTP)
      RETURN
      END
