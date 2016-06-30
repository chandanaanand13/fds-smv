% McDermott
% 2-15-10
% sandia_helium_plume.m
%
% Plot Sandia 1m helium plume data and FDS results

close all
clear all

addpath '../../Validation/Sandia_Plumes/Experimental_Data'
addpath '../../Validation/Sandia_Plumes/FDS_Output_Files'

exp_stride = 4;

% Experimental error (relative) is taken from Sec. II of
%
% Desjardin et al. Large-eddy simulation and experimental measurements of the near-field of a large turbulent helium plume.
% Physics of Fluids, Vol. 16, No. 6, June 2004.

% vertical velocity

radial_profile('Sandia_Plumes/Sandia_He_1m_W2','col',2,0.2,'relative',10, ...
               'Radial Position (m)','Vertical Velocity (m/s)','Sandia Helium Plume','{\itz} = 0.2 m','Northeast', ...
               -.5,.5,.05,-.5,.5,.1,0,5,1,'Sandia_He_1m_dx6cm_git.txt', ...
               'Sandia_He_1m_W_zp2.csv','bo','Exp',exp_stride, ...
               'Sandia_He_1m_dx6cm_line.csv','b-.','FDS 6 cm', ...
               'Sandia_He_1m_dx3cm_line.csv','b--','FDS 3 cm', ...
               'Sandia_He_1m_dx1p5cm_line.csv','b-','FDS 1.5 cm')
           
radial_profile('Sandia_Plumes/Sandia_He_1m_W4','col',3,0.2,'relative',10, ...
               'Radial Position (m)','Vertical Velocity (m/s)','Sandia Helium Plume','{\itz} = 0.4 m','Northeast', ...
               -.5,.5,.05,-.5,.5,.1,0,5,1,'Sandia_He_1m_dx6cm_git.txt', ...
               'Sandia_He_1m_W_zp4.csv','bo','Exp',exp_stride, ...
               'Sandia_He_1m_dx6cm_line.csv','b-.','FDS 6 cm', ...
               'Sandia_He_1m_dx3cm_line.csv','b--','FDS 3 cm', ...
               'Sandia_He_1m_dx1p5cm_line.csv','b-','FDS 1.5 cm')

radial_profile('Sandia_Plumes/Sandia_He_1m_W6','col',4,0.2,'relative',10, ...
               'Radial Position (m)','Vertical Velocity (m/s)','Sandia Helium Plume','{\itz} = 0.6 m','Northeast', ...
               -.5,.5,.05,-.5,.5,.1,0,5,1,'Sandia_He_1m_dx6cm_git.txt', ...
               'Sandia_He_1m_W_zp6.csv','bo','Exp',exp_stride, ...
               'Sandia_He_1m_dx6cm_line.csv','b-.','FDS 6 cm', ...
               'Sandia_He_1m_dx3cm_line.csv','b--','FDS 3 cm', ...
               'Sandia_He_1m_dx1p5cm_line.csv','b-','FDS 1.5 cm')
           
% radial velocity

radial_profile('Sandia_Plumes/Sandia_He_1m_U2','col',5,0.2,'relative',10, ...
               'Radial Position (m)','Radial Velocity (m/s)','Sandia Helium Plume','{\itz} = 0.2 m','Northeast', ...
               -.5,.5,.05,-.5,.5,.1,-1,1,.25,'Sandia_He_1m_dx6cm_git.txt', ...
               'Sandia_He_1m_U_zp2.csv','ro','Exp',exp_stride, ...
               'Sandia_He_1m_dx6cm_line.csv','r-.','FDS 6 cm', ...
               'Sandia_He_1m_dx3cm_line.csv','r--','FDS 3 cm', ...
               'Sandia_He_1m_dx1p5cm_line.csv','r-','FDS 1.5 cm')
           
radial_profile('Sandia_Plumes/Sandia_He_1m_U4','col',6,0.2,'relative',10, ...
               'Radial Position (m)','Radial Velocity (m/s)','Sandia Helium Plume','{\itz} = 0.4 m','Northeast', ...
               -.5,.5,.05,-.5,.5,.1,-1,1,.25,'Sandia_He_1m_dx6cm_git.txt', ...
               'Sandia_He_1m_U_zp4.csv','ro','Exp',exp_stride, ...
               'Sandia_He_1m_dx6cm_line.csv','r-.','FDS 6 cm', ...
               'Sandia_He_1m_dx3cm_line.csv','r--','FDS 3 cm', ...
               'Sandia_He_1m_dx1p5cm_line.csv','r-','FDS 1.5 cm')
           
radial_profile('Sandia_Plumes/Sandia_He_1m_U6','col',7,0.2,'relative',10, ...
               'Radial Position (m)','Radial Velocity (m/s)','Sandia Helium Plume','{\itz} = 0.6 m','Northeast', ...
               -.5,.5,.05,-.5,.5,.1,-1,1,.25,'Sandia_He_1m_dx6cm_git.txt', ...
               'Sandia_He_1m_U_zp6.csv','ro','Exp',exp_stride, ...
               'Sandia_He_1m_dx6cm_line.csv','r-.','FDS 6 cm', ...
               'Sandia_He_1m_dx3cm_line.csv','r--','FDS 3 cm', ...
               'Sandia_He_1m_dx1p5cm_line.csv','r-','FDS 1.5 cm')
           
% helium mass fraction

radial_profile('Sandia_Plumes/Sandia_He_1m_YHe2','col',8,0.23,'relative',10, ...
               'Radial Position (m)','Helium Mass Fraction','Sandia Helium Plume','{\itz} = 0.2 m','Northeast', ...
               -.5,.5,.05,-.5,.5,.1,0,1,.2,'Sandia_He_1m_dx6cm_git.txt', ...
               'Sandia_He_1m_YHe_zp2.csv','ko','Exp',exp_stride, ...
               'Sandia_He_1m_dx6cm_line.csv','k-.','FDS 6 cm', ...
               'Sandia_He_1m_dx3cm_line.csv','k--','FDS 3 cm', ...
               'Sandia_He_1m_dx1p5cm_line.csv','k-','FDS 1.5 cm')
           
radial_profile('Sandia_Plumes/Sandia_He_1m_YHe4','col',9,0.23,'relative',10, ...
               'Radial Position (m)','Helium Mass Fraction','Sandia Helium Plume','{\itz} = 0.4 m','Northeast', ...
               -.5,.5,.05,-.5,.5,.1,0,1,.2,'Sandia_He_1m_dx6cm_git.txt', ...
               'Sandia_He_1m_YHe_zp4.csv','ko','Exp',exp_stride, ...
               'Sandia_He_1m_dx6cm_line.csv','k-.','FDS 6 cm', ...
               'Sandia_He_1m_dx3cm_line.csv','k--','FDS 3 cm', ...
               'Sandia_He_1m_dx1p5cm_line.csv','k-','FDS 1.5 cm')
           
radial_profile('Sandia_Plumes/Sandia_He_1m_YHe6','col',10,0.23,'relative',10, ...
               'Radial Position (m)','Helium Mass Fraction','Sandia Helium Plume','{\itz} = 0.6 m','Northeast', ...
               -.5,.5,.05,-.5,.5,.1,0,1,.2,'Sandia_He_1m_dx6cm_git.txt', ...
               'Sandia_He_1m_YHe_zp6.csv','ko','Exp',exp_stride, ...
               'Sandia_He_1m_dx6cm_line.csv','k-.','FDS 6 cm', ...
               'Sandia_He_1m_dx3cm_line.csv','k--','FDS 3 cm', ...
               'Sandia_He_1m_dx1p5cm_line.csv','k-','FDS 1.5 cm')


% vertical velocity rms

radial_profile('Sandia_Plumes/Sandia_He_1m_Wrms_p2','col',11,0.3,'relative',10, ...
               'Radial Position (m)','RMS Vertical Velocity (m/s)','Sandia Helium Plume','{\itz} = 0.2 m','Northeast', ...
               -.5,.5,.05,-.5,.5,.1,0,2,.25,'Sandia_He_1m_dx6cm_git.txt', ...
               'Sandia_He_1m_Wrms_p2.csv','bo','Exp',exp_stride, ...
               'Sandia_He_1m_dx6cm_line.csv','b-.','FDS 6 cm', ...
               'Sandia_He_1m_dx3cm_line.csv','b--','FDS 3 cm', ...
               'Sandia_He_1m_dx1p5cm_line.csv','b-','FDS 1.5 cm')
           
radial_profile('Sandia_Plumes/Sandia_He_1m_Wrms_p4','col',12,0.3,'relative',10, ...
               'Radial Position (m)','RMS Vertical Velocity (m/s)','Sandia Helium Plume','{\itz} = 0.4 m','Northeast', ...
               -.5,.5,.05,-.5,.5,.1,0,2,.25,'Sandia_He_1m_dx6cm_git.txt', ...
               'Sandia_He_1m_Wrms_p4.csv','bo','Exp',exp_stride, ...
               'Sandia_He_1m_dx6cm_line.csv','b-.','FDS 6 cm', ...
               'Sandia_He_1m_dx3cm_line.csv','b--','FDS 3 cm', ...
               'Sandia_He_1m_dx1p5cm_line.csv','b-','FDS 1.5 cm')

radial_profile('Sandia_Plumes/Sandia_He_1m_Wrms_p6','col',13,0.3,'relative',10, ...
               'Radial Position (m)','RMS Vertical Velocity (m/s)','Sandia Helium Plume','{\itz} = 0.6 m','Northeast', ...
               -.5,.5,.05,-.5,.5,.1,0,2,.25,'Sandia_He_1m_dx6cm_git.txt', ...
               'Sandia_He_1m_Wrms_p6.csv','bo','Exp',exp_stride, ...
               'Sandia_He_1m_dx6cm_line.csv','b-.','FDS 6 cm', ...
               'Sandia_He_1m_dx3cm_line.csv','b--','FDS 3 cm', ...
               'Sandia_He_1m_dx1p5cm_line.csv','b-','FDS 1.5 cm')
           
           
% radial velocity rms

radial_profile('Sandia_Plumes/Sandia_He_1m_Urms_p2','col',14,0.3,'relative',10, ...
               'Radial Position (m)','RMS Radial Velocity (m/s)','Sandia Helium Plume','{\itz} = 0.2 m','Northeast', ...
               -.5,.5,.05,-.5,.5,.1,0,1,.25,'Sandia_He_1m_dx6cm_git.txt', ...
               'Sandia_He_1m_Urms_p2.csv','ro','Exp',exp_stride, ...
               'Sandia_He_1m_dx6cm_line.csv','r-.','FDS 6 cm', ...
               'Sandia_He_1m_dx3cm_line.csv','r--','FDS 3 cm', ...
               'Sandia_He_1m_dx1p5cm_line.csv','r-','FDS 1.5 cm')
           
radial_profile('Sandia_Plumes/Sandia_He_1m_Urms_p4','col',15,0.3,'relative',10, ...
               'Radial Position (m)','RMS Radial Velocity (m/s)','Sandia Helium Plume','{\itz} = 0.4 m','Northeast', ...
               -.5,.5,.05,-.5,.5,.1,0,1,.25,'Sandia_He_1m_dx6cm_git.txt', ...
               'Sandia_He_1m_Urms_p4.csv','ro','Exp',exp_stride, ...
               'Sandia_He_1m_dx6cm_line.csv','r-.','FDS 6 cm', ...
               'Sandia_He_1m_dx3cm_line.csv','r--','FDS 3 cm', ...
               'Sandia_He_1m_dx1p5cm_line.csv','r-','FDS 1.5 cm')
           
radial_profile('Sandia_Plumes/Sandia_He_1m_Urms_p6','col',16,0.3,'relative',10, ...
               'Radial Position (m)','RMS Radial Velocity (m/s)','Sandia Helium Plume','{\itz} = 0.6 m','Northeast', ...
               -.5,.5,.05,-.5,.5,.1,0,1,.25,'Sandia_He_1m_dx6cm_git.txt', ...
               'Sandia_He_1m_Urms_p6.csv','ro','Exp',exp_stride, ...
               'Sandia_He_1m_dx6cm_line.csv','r-.','FDS 6 cm', ...
               'Sandia_He_1m_dx3cm_line.csv','r--','FDS 3 cm', ...
               'Sandia_He_1m_dx1p5cm_line.csv','r-','FDS 1.5 cm')

           
% helium mass fraction rms

radial_profile('Sandia_Plumes/Sandia_He_1m_Yrms_p2','col',17,0.21,'relative',10, ...
               'Radial Position (m)','RMS Helium Mass Fraction','Sandia Helium Plume','{\itz} = 0.2 m','Northeast', ...
               -.5,.5,.05,-.5,.5,.1,0,.25,.05,'Sandia_He_1m_dx6cm_git.txt', ...
               'Sandia_He_1m_Yrms_p2.csv','ko','Exp',exp_stride, ...
               'Sandia_He_1m_dx6cm_line.csv','k-.','FDS 6 cm', ...
               'Sandia_He_1m_dx3cm_line.csv','k--','FDS 3 cm', ...
               'Sandia_He_1m_dx1p5cm_line.csv','k-','FDS 1.5 cm')
           
radial_profile('Sandia_Plumes/Sandia_He_1m_Yrms_p4','col',18,0.21,'relative',10, ...
               'Radial Position (m)','RMS Helium Mass Fraction','Sandia Helium Plume','{\itz} = 0.4 m','Northeast', ...
               -.5,.5,.05,-.5,.5,.1,0,.25,.05,'Sandia_He_1m_dx6cm_git.txt', ...
               'Sandia_He_1m_Yrms_p4.csv','ko','Exp',exp_stride, ...
               'Sandia_He_1m_dx6cm_line.csv','k-.','FDS 6 cm', ...
               'Sandia_He_1m_dx3cm_line.csv','k--','FDS 3 cm', ...
               'Sandia_He_1m_dx1p5cm_line.csv','k-','FDS 1.5 cm')          
 
radial_profile('Sandia_Plumes/Sandia_He_1m_Yrms_p6','col',19,0.21,'relative',10, ...
               'Radial Position (m)','RMS Helium Mass Fraction','Sandia Helium Plume','{\itz} = 0.6 m','Northeast', ...
               -.5,.5,.05,-.5,.5,.1,0,.25,.05,'Sandia_He_1m_dx6cm_git.txt', ...
               'Sandia_He_1m_Yrms_p6.csv','ko','Exp',exp_stride, ...
               'Sandia_He_1m_dx6cm_line.csv','k-.','FDS 6 cm', ...
               'Sandia_He_1m_dx3cm_line.csv','k--','FDS 3 cm', ...
               'Sandia_He_1m_dx1p5cm_line.csv','k-','FDS 1.5 cm')         
           
