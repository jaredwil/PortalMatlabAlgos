From: <Saved by Microsoft Internet Explorer 5>
Subject: 
Date: Wed, 16 Nov 2005 08:29:58 -0500
MIME-Version: 1.0
Content-Type: text/html;
	charset="Windows-1252"
Content-Transfer-Encoding: quoted-printable
Content-Location: http://www.mathworks.com/matlabcentral/files/8225/naninterp.m
X-MimeOLE: Produced By Microsoft MimeOLE V6.00.2900.2180

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<HTML><HEAD>
<META http-equiv=3DContent-Type content=3D"text/html; =
charset=3Dwindows-1252">
<META content=3D"MSHTML 6.00.2900.2769" name=3DGENERATOR></HEAD>
<BODY><PRE>function X =3D naninterp(X)
% Interpolate over NaNs
% See INTERP1 for more info
X(isnan(X)) =3D interp1(find(~isnan(X)), X(~isnan(X)), =
find(isnan(X)),'cubic');
return</PRE></BODY></HTML>
