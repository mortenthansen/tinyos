function importance_graph(data, id, runs, energy)

%id = 1;
MAX_ENERGY = energy*65768;
%RUNS = 5;

names = fields(data);
names = sortrows(names);

% lifetime and importance
stats = zeros(length(names),2);

%% Get stats from node

for n=1:length(names)
    nodes = data.(char(names(n)));
    node = get_node(nodes, id);
    
    [s e ext mat tok nam] = regexp(char(names(n)),'threshold(?<threshold>[0-9]*|VAR)_run(?<run>[0-9])*');
    threshold = nam.threshold;
    run = str2double(nam.run);

    die_index = find(node.Selective__ENERGY_USED(:,2)<MAX_ENERGY==0,1);
    
    if isempty(die_index)        
        error(sprintf('die_index is empty as %d<%d in %s',...
            round(node.Selective__ENERGY_USED(end,2)/65768),...
            round(MAX_ENERGY/65768),...
            char(names(n))))
    end
    
    ts = node.Selective__ENERGY_USED(die_index,1);
    
    times = node.Selective__FORWARD(:,1);
    
    localtime_index = find(node.LOCALTIME(:,1)<ts==1,1,'last');
    
    stats(n,1) = node.LOCALTIME(localtime_index,2)/1024/1024*1000; %ts - node.App__BOOTED(1,1);
    stats(n,2) = sum(node.Selective__FORWARD(times<ts,2));
    
    %nodes.MoteStats__IDLE(:,2)
    %nodes.MoteStats__IDLE(1,1)
    %max_time = max(node.LOCALTIME(:,2))
    
end

names;
stats;

%% Get average lifetime and importances for each threshold

mean_lifetime = zeros(length(names)/runs,1);
min_importance = zeros(length(names)/runs,1);
mean_importance = zeros(length(names)/runs,1);
max_importance = zeros(length(names)/runs,1);
texts = cell(length(names)/runs,1);
n = 1;
while n<=length(names)
    if runs==1
        index = n;
    else
        index = floor(n/runs+1);
    end
    mean_lifetime(index) = mean(stats(n:n+runs-1,1));
    min_importance(index) = min(stats(n:n+runs-1,2));
    mean_importance(index) = mean(stats(n:n+runs-1,2));
    max_importance(index) = max(stats(n:n+runs-1,2));
	[s e ext mat tok nam] = regexp(char(names(n)),'threshold(?<threshold>[0-9]*|VAR)_run(?<run>[0-9])*');
    texts{index} = nam.threshold;
    n = n + runs;
end

texts;
mean_lifetime;
min_importance;
mean_importance;
max_importance;

%% Create importance sum figure

figure('Name','Importance Sum')
errorbar(mean_lifetime, mean_importance, mean_importance-min_importance, max_importance-mean_importance, 'o', 'LineWidth', 2, 'MarkerSize', 5)
for n=1:length(names)/runs
    text(mean_lifetime(n)+20,mean_importance(n),texts(n),'FontSize',15)
end
ylabel('Importance Sum [importance]')
xlabel('Lifetime [s]')

function node = get_node(nodes, id)
for n=1:length(nodes)
    if nodes(n).id==id
        node = nodes(n);
        break
    end
end