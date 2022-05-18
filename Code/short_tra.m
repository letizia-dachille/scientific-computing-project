function [x,x1t,r,mv] = short_tra(H,alpha,v,v1,m,p,tol,mv)
% function [x,x1t,r,mv] = short_tra(H,alpha,v,v1,m,p,tol,mv)
% Input - H: adjacency matrix
%		  alpha: damping factor
%		  v: personalization vector
%		  v1: unit positive initial
%		  m: dimension of the Krylov subspace
%		  p: number of approximate eigenpairs which are wanted
%		  tol: prescribed tolerance
%		  mv: number of matrix-vector products
% Output - x: PageRank vector
%		   x1t: approximation vector to be used in PET or power iteration
%		   r: residual norm
%		   mv: number of matrix-vector products

% Apply Algorithm 2 to form Vm1 = V_{m+1}, H_m, Hb = \bar{H_m}. 
[Hb,Vm1] = thick_arnoldi_process(H,alpha,v,v1,[],m);
mv = mv + m;
Hm = Hb(1:m,:);

% Compute all the eigenpairs (li, yi) (i = 1, 2, ... , m) of the matrix Hm.
[Y,L] = eig(Hm);
L = diag(L);

% Then select p largest of them.
[~,I] = sort(abs(L),'descend');
Y = Y(:,I);
Y = Y(:,1:p);

em = zeros(m,1);
em(m) = 1;
em1 = [0;em];

% Iterations.
s = 0;

r = Hb(m+1,m)*abs(em'* Y(:,1));

% Check convergence. If the largest eigenpairs is accurate enough, i.e., 
% hm+1,m|e_m^T y1|<= tol, then take x1 = Vm y1 as an approximation to the 
% PageRank vector and stop, else continue.
while r > tol && s < 2
	
	% Separate yi into real part and imaginary part 
    % if it is complex. Both parts of complex vectors need to be included, so 
    % temporarily reduce p by 1 if necessary (or p can be increased by 1).
	Wp = zeros(m,p-1);
	p1 = 1;
	i = 1;
	while i <= p
		if sum(round(real(Y(:,i)),10) ~= zeros(m,1))
			Wp(:,p1) = real(Y(:,i));
			p1 = p1 + 1;
		end
		if sum(round(imag(Y(:,i)),10) ~= zeros(m,1))
			Wp(:,p1) = imag(Y(:,i));
			p1 = p1 + 1;
			i = i + 1;
		end
		if p1 > p
			break;
		end
		i = i + 1;
	end
	
    % Orthonormalize yi (i = 1, 2, ... , p) to form a m x p matrix.
    Wp = gramschmidt(Wp);
    p1 = size(Wp,2);

    % By appending a zeros row at the bottom of the matrix Wp, form a real 
    % (m + 1) x p matrix Wpt = [Wp;O], and set
    % Wp+1 = [Wpt , em+1 ], where em+1 is the (m + 1)th co-ordinate vector. Note 
    % that Wp+1 is an (m + 1) x (p + 1) orthonormal matrix.
    Wpt = [Wp;zeros(1,p1)];
    Wp1 = [Wpt,em1];

    % Use the old Vm+1 and Hm to form portions of the new Vm+1 and Hm. Let 
    % Vp+1 = Vm+1Wp+1, \bar{Hp} = Wp+1^T\bar{Hm}Wp, return to step 3.
    Vp1 = Vm1 * Wp1;
    Hpb = Wp1' * Hb * Wp;

    % Apply the Arnoldi process from the current point vp+1 to form 
    % Vm+1,Hm,\bar{Hm}. Compute all the eigenpairs (li,yi) (i = 1, 2, ... , m)
    % of the matrix Hm. Then select p largest of them.
    [Hb,Vm1] = thick_arnoldi_process(H,alpha,v,Vp1,Hpb,m);
	mv = mv + m - p1;
    Hm = Hb(1:m,:);
    [Y,L] = eig(Hm);
    L = diag(L);
    [~,I] = sort(abs(L),'descend');
    Y = Y(:,I);
    Y = Y(:,1:p);    
	
	s = s + 1;
	
	r = Hb(m+1,m)*abs(em'* Y(:,1));
end

x = Vm1(:,1:m) * Y(:,1);
x = sign(sum(x))*x;
x = x/norm(x,1);

x1t = Vm1(:,1);