function generate_graphs()

%energy = 200; % use this for the logs below
%folder = '1b_smallramp1to128_lpl512_delay10_period2048_init9_battery200';
%folder = '2b_smallramp1to128_lpl512_delay10_period2048_init9_battery200';
%folder = '3b_smallramp1to128_lpl512_delay10_period2048_init9_battery200';

energy = 600; % use this for the logs below
folder = '1b_smallramp1to128_lpl512_delay10_period2048_init9_battery600';
%folder = '2b_smallramp1to128_lpl512_delay10_period2048_init9_battery600';
%folder = '3b_smallramp1to128_lpl512_delay10_period2048_init9_battery600';

files = what(folder);
files = files.mat;

for f=1:length(files)
    load(strcat(folder,'/',files{f}));
    [name ext] = strtok(files{f},'.');
    data.(name) = nodes;
end

importance_graph(data, 1, 5, energy);
stats_graph(data, 1, 5);
evolution_graph(data, 1, 5);