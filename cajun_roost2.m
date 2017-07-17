%CAJUN_GEN_IMAGES Create cajun images

dir = '/home/sgabriel/output'; 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Constants
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

MAX_ELEV_ANGLE          = 5;      % read sweeps up to this elevation
GAUTHREAUX_THRESHOLD    = 5;      % Threshold for Gauthreaux-in-a-box in m/s

CLUTTER_YEARS  = 2008:2015; %[2010, 2011];
CLUTTER_MONTHS = 03:05; %[8, 9, 10, 11];

% Parameters for epvvp. All units are in meters
RMIN_M  = 5000;
RMAX_M  = 75000; % <- larger max radius for gulf coast --> smaller for Northeast 37500;
ZSTEP_M = 100;
ZMAX_M  = 3000;
RMSE_THRESH = inf;
EP_GAMMA = 0.1;

% Paramters for align_scan
AZ_RES    = 0.5;
RANGE_RES = 250;

radar_file = '~/scans/KDOX20111001_111742_V04.gz';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Main processing loop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf('Processing %s. . .\n', scan_name);
fprintf('Radar file is %s\n', radar_file);

profile = struct();
    
% Read radar
radar = rsl2mat(radar_file, station, struct('cartesian', false, 'max_elev', MAX_ELEV_ANGLE));

% Dealias
%radar_dealiased = vvp_dealias(radar, edges, u, v, rmse, RMSE_THRESH);

% Align to fixed grid and extract data matrices
radar_aligned = align_scan(radar, AZ_RES, RANGE_RES, RMAX_M , 'nearest', true);
[data, range, az, elev] = radar2mat(radar_aligned, {'dz', 'vr'});
DZ = data{1};
VR = data{2};
[RANGE, AZ, ELEV] = ndgrid(range, az, elev);
[~, HEIGHT] = slant2ground(RANGE, ELEV);      % height (m above radar) of each pulse volume

%if clutterMask failed to load for some reason, make a dummy mask the same size as the data
sz = size(DZ);
if isempty(clutterMask)
    clutterMask = zeros(sz);
end

% Trim/fill clutter mask
if sz(1) > size(clutterMask,1)
    clutterMask = cat(1, clutterMask, zeros(sz(1)-size(clutterMask,1),sz(2),sz(3)));
else
    clutterMask = clutterMask(1:sz(1), :, :);
end

% Classify pulse volumes
BIRD = 0;
NODATA = 1;
STATIC = 2;
DYNAMIC = 3;
WIND_BORNE = 4;
OUTSIDE_WEDGE = 5;
        
MASK = zeros(sz);                                           % birds
MASK(isnan(DZ) | isnan(VR)) = NODATA;                       % no return, range-folding, etc
MASK(abs(VR) < 1) = DYNAMIC;                                % dynamic clutter
MASK(clutterMask > 0) = STATIC;                             % static clutter

% Set masked volumes to -inf or nan
%   -inf = count as zero reflectivity
%    nan = exclude from calculation
MASKED_DZ = DZ;
MASKED_DZ(MASK == NODATA)        = -inf;
MASKED_DZ(MASK == DYNAMIC)       = nan;
MASKED_DZ(MASK == STATIC)        = nan;

vrlim = [-20, 20];
velmap = vrmap2(32);

dzlim = [-5 30];
dzmap = jet(32);

mask_map = lines(6);
mask_legend = {'birds', 'nodata', 'static clutter', 'dynamic clutter', 'wind-borne', 'outside wedge'};

dim = 400;
rmax = max(range);
type = 'nearest';

nsweeps = 3;

zmax = max(prof.bin_upper);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% IMAGES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

sz = size(MASK);

sweeps = unique_elev_sweeps(radar, 'vr');

for i=1:min(nsweeps, sz(3))
    
    raw_vr_im    = sweep2cart(      sweeps(i), rmax, dim, type, false);
    
    mask_im      = mat2cart(      MASK(:,:,i), az, range, dim, rmax, type);
    vr_im        = mat2cart(        VR(:,:,i), az, range, dim, rmax, type);
    dz_im        = mat2cart(        DZ(:,:,i), az, range, dim, rmax, type);
    masked_dz_im = mat2cart( MASKED_DZ(:,:,i), az, range, dim, rmax, type);
    
    imwrite_gif_nan(mask_im + 1, mask_map, sprintf('%s/mask_%d.gif', dir, i));
    
    raw_vr_gif = mat2ind(raw_vr_im, vrlim, velmap);
    imwrite_gif_nan(raw_vr_gif, velmap, sprintf('%s/raw_vr_%d.gif', dir, i));
    
    vr_gif = mat2ind(vr_im, vrlim, velmap);
    imwrite_gif_nan(vr_gif, velmap, sprintf('%s/vr_%d.gif', dir, i));
    
    dz_gif = mat2ind(dz_im, dzlim, dzmap);
    imwrite_gif_nan(dz_gif, dzmap, sprintf('%s/dz_%d.gif', dir, i));
    
    masked_dz_gif = mat2ind(masked_dz_im, dzlim, dzmap);
    imwrite_gif_nan(masked_dz_gif, dzmap, sprintf('%s/masked_dz_%d.gif', dir, i));
    
end

close(elev_profile);