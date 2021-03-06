%------------------------------------------------------------------------------
%   Simulink scrip for listing dictionary parameters
%   MATLAB       : R2017a
%   Author       : Shibo Jiang 
%   Version      : 0.7
%   Time         : 2017/12/7
%   Instructions : Fix bugs ,modify temp name as '____'   - 0.4
%                  Add datasource information             - 0.5
%                  Fix bugs, messeage can report clearly  - 0.6
%                  Code refactoring.
%                  Adapt to MyPkg class searching         - 0.7
%                  Add stateflow parameter                - 0.8
%                  Fix bugs                               - 0.9
%------------------------------------------------------------------------------
function output = list_parameter()

    paraModel = bdroot;

    % Original matalb version is R2017a
    % 检查Matlab版本是否为R202017a
    CorrectVersion_win = '9.2.0.556344 (R2017a)';    % windows
    CorrectVersion_linux =  '9.2.0.538062 (R2017a)';   % linux
    CurrentVersion = version;
    if 1 ~= bitor(strcmp(CorrectVersion_win, CurrentVersion),...
                strcmp(CorrectVersion_linux, CurrentVersion))
    warning(['Matlab version mismatch, this scrip should be' ...
             'used for Matlab R2017a']); 
    end

    % % Get inter parameter which defined in model workspace
    % simulink_var_space = get_param(paraModel,'ModelWorkspace');
    % simulink_par_inter = simulink_var_space.whos;

    % Get outlink parameter which defined in data dictionary
    data_dictionary = get_param(paraModel, 'DataDictionary');
    current_dic = Simulink.data.dictionary.open(data_dictionary);
    dic_entry = getSection(current_dic, 'Design Data');
    simulink_par_database = find(dic_entry);

    % Get all parameter's name and mark the line which has same name
    len_dict = length(simulink_par_database);
    for index = 1:len_dict
        par_name{index} = simulink_par_database(index).Name;
        par_name_source{index} = simulink_par_database(index).DataSource;
        % Mark the line
        line_marked{index} = find_system(paraModel,'FindAll','on','type'...
                                         ,'line','Name',par_name{index});
        set_param(line_marked{index}, 'Name', [par_name{index},'____']);
    end
    par_name = par_name';

    % Get line's name which is not defined in dictionary
    all_line = find_system(paraModel,'FindAll','on','type','line');
    j = 1;
    APPEND_LENGTH = 4;
    for i = 1:length(all_line)
        current_line_name = get(all_line(i), 'Name');
        try
            if strcmp('____', current_line_name((end-APPEND_LENGTH+1):end))
                % Revert the line's name
                set_param(all_line(i), 'Name', ...
                          current_line_name(1:(end - (APPEND_LENGTH))));
            else
                only_line_name{j} = current_line_name;
                j = j + 1;
            end
        end
    end

    % Find and mark the simulink parameter & table
    simu_par = find(dic_entry,'-value','-class','Simulink.Parameter');
    mypkg_par = find(dic_entry,'-value','-class','MyPkg.Parameter');
    simulink_par = [simu_par; mypkg_par];
    len_simu_par = length(simulink_par);
    index_table = 1;
    index_par = 1;
    % Macro define which used in table
    TABLE_NAME = 1;
    TABLE_SOURCE = 2;
    TABLE_DATATYPE = 3;
    TABLE_STORAGE = 4;
    TABLE_DIM = 5;
    TABLE_VALUE = 6;
    if 0 < len_simu_par
        for i = 1:len_simu_par
            simu_par_temp = getValue(simulink_par(i));
            simu_par_temp_name = simulink_par(i).Name;
            simu_par_temp_source = simulink_par(i).DataSource;
            simu_par_temp_datatype = simu_par_temp.DataType;
            simu_par_temp_stor = simu_par_temp.CoderInfo.StorageClass;
            simu_par_temp_dim = simu_par_temp.Dimensions;
            simu_par_temp_value = simu_par_temp.Value;

            if [1, 1] == simu_par_temp_dim
                simu_par_name{index_par} = simu_par_temp_name;
                simu_par_source{index_par} = simu_par_temp_source;
                simu_par_datatype{index_par} = simu_par_temp_datatype;
                simu_par_storage{index_par} = simu_par_temp_stor;
                simu_par_value{index_par} = simu_par_temp_value;
                index_par = index_par + 1;
            else
                simu_table{index_table} = {simu_par_temp_name, ...
                                           simu_par_temp_source,...
                                           simu_par_temp_datatype, ...
                                           simu_par_temp_stor, ...
                                           simu_par_temp_dim, ...
                                           simu_par_temp_value};
                index_table = index_table + 1;
            end
        end
    end

    output = 'Listing is running.'

    % Find stateflow parameter
    sf = sfroot;
    sf_parameter = sf.find('-isa','Stateflow.Data');
    len_sf = 0;
    if isempty(sf_parameter)
        output = 'There is no state flow parameter in this model'
    else
        len_sf = length(sf_parameter);
        for i = 1:len_sf
            sf_par_name{i} = sf_parameter(i).Name;
            sf_par_datatype{i} = sf_parameter(i).DataType;
            sf_par_scope{i} = sf_parameter(i).Scope;
        end
    end

    % Define table name
    filename = [paraModel,'_list.xlsx'];
    table_name_change_history = {'Version', 'Change History', 'Name', 'Notes'};
    warning off MATLAB:xlswrite:AddSheet;
    xlswrite(filename, table_name_change_history, 1, 'A1');
    table_name_dict = {'No.', 'Old Name', 'New Name', 'Data Source'};
    xlswrite(filename, table_name_dict, 'dict', 'A1');
    table_name_only_line = {'No.', 'Old Name', 'New Name'};
    xlswrite(filename, table_name_only_line, 'only_line', 'A1')
    table_name_simu_par = {'No.', 'Name', 'Data Source','Data Type',...
                           'Storage Class', 'Value'};
    xlswrite(filename, table_name_simu_par, 'simu_parameter', 'A1');
    table_name_table = {'No.', 'Name','Data Source', 'Data Type',...
                        'Storage Class', 'Row', 'Column','Value'};
    xlswrite(filename, table_name_table, 'simu_table', 'A1');
    table_name_sf = {'No.', 'Name', 'Scope', 'Data Type'};
    xlswrite(filename, table_name_sf, 'sf_parameter', 'A1');

    % Write parameters to excel
    if 0 < len_dict
        number_par = [1:1:len_dict]';
        xlswrite(filename, number_par, 'dict', 'A2');
        xlswrite(filename, par_name, 'dict', 'B2');
        xlswrite(filename, par_name, 'dict', 'C2');
        xlswrite(filename, par_name_source', 'dict', 'D2');
    else
        output = 'This model has no dictionary.'
    end

    % Write only line's name to excel
    if 1 < j
        number_only_line = [1:1:(j-1)]';
        only_line_name = only_line_name';
        xlswrite(filename, number_only_line, 'only_line', 'A2');
        xlswrite(filename, only_line_name, 'only_line', 'B2');
        xlswrite(filename, only_line_name, 'only_line', 'C2');
    else
        output = ['This model has no ',...
                          'name which defined on line only.']
    end

    % Write simulink parameters to excel
    if 1 < index_par
        number_simu_par = [1:1:(index_par-1)]';
        xlswrite(filename, number_simu_par, 'simu_parameter', 'A2');
        xlswrite(filename, simu_par_name', 'simu_parameter', 'B2');
        xlswrite(filename, simu_par_source', 'simu_parameter', 'C2');
        xlswrite(filename, simu_par_datatype', 'simu_parameter', 'D2');
        xlswrite(filename, simu_par_storage', 'simu_parameter', 'E2')
        xlswrite(filename, simu_par_value', 'simu_parameter', 'F2');
    else
        output = 'This model has no simulink parameter defined in dictionary.'
    end

    % Write table data to excel
    if 1 < index_table
        temp_dim = 1;
        for i = 1:(index_table-1)
            % Calculate write position
            temp_pos = num2str(1 + temp_dim);
            table_num_position = ['A' temp_pos];
            table_name_position = ['B' temp_pos];
            table_source_position = ['C' temp_pos];
            table_datatype_position = ['D' temp_pos];
            table_storage_position = ['E' temp_pos];
            table_dim_position = ['F' temp_pos];
            % table_dim_column_position = ['G' temp_pos];
            table_value_position = ['H' temp_pos];
            % Start writing
            xlswrite(filename, i, 'simu_table', ...
                     table_num_position);
            xlswrite(filename, simu_table{i}(TABLE_NAME),...
                     'simu_table', table_name_position);
            xlswrite(filename, simu_table{i}(TABLE_SOURCE),...
                     'simu_table', table_source_position);
            xlswrite(filename, simu_table{i}(TABLE_DATATYPE),...
                     'simu_table', table_datatype_position);
            xlswrite(filename, simu_table{i}(TABLE_STORAGE),...
                     'simu_table', table_storage_position);
            xlswrite(filename, simu_table{i}{TABLE_DIM},...
                     'simu_table', table_dim_position);
            try
                xlswrite(filename, simu_table{i}{TABLE_VALUE},...
                         'simu_table',  table_value_position);
            end
                    
            temp_dim = temp_dim + simu_table{i}{TABLE_DIM}(1);
        end
    else
        output = 'This model has no table parameter.'
    end

    % Write stateflow parameter to Excel
    if 0 < len_sf
        number_sf = [1:1:len_sf]';
        xlswrite(filename, number_sf, 'sf_parameter', 'A2');
        xlswrite(filename, sf_par_name', 'sf_parameter', 'B2');
        xlswrite(filename, sf_par_scope', 'sf_parameter', 'C2');
        xlswrite(filename, sf_par_datatype', 'sf_parameter', 'D2');
    end

    % close the dictionary 
    close(current_dic);
    output = 'Listing name successful.';
    
end