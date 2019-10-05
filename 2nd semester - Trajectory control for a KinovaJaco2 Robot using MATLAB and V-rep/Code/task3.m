% Template to visualize in V-REP the inverse kinematics algorithm developed
%          for the kinova Jaco 2 7-DOF robot
%
% Read Instructions.odt first !
% 
% Do not modify any part of this file except the strings within
%    the symbols << >>
%
% G. Antonelli, Introduction to Robotics, spring 2019


function [t, q, q_act] = main_template
    close all
    clear all
    clc
    addpath('matlabVrep_lib/');
    addpath('functions/');
    porta = 19997;              % default V-REP port
    
    % excution variables
    sideLen = 0.1;              % length of each side of the square in(m)
    tf = 2;                     % time of movement from corner to corner
    t_final = (2*4)+(0.2*3)+3;  % total excution time
    Ts = 0.001;                 % sampling time
    t  = 0:Ts:t_final;          % time vector           
    N  = length(t);             % number of points of the simulation 
    n = 7;                      % joint number
    pd = zeros(3,N);           % desired position at each point
    dpd = zeros(3,N);
    pc = zeros(3,N);           % current position at each point
    
    % taks 3
    ang_f = (20*pi/180);       % rotation angle of ee at each line
    ang = zeros(1,N);
    dang = zeros(1,N);
    
    q      = zeros(n,N);    % q(:,i) collects the joint position for t(i) %joint position current - 7 joint positions
    q_jaco = zeros(n,N);    % q_jaco(:,i) collects the joint position for t(i) in Kinova convention %joint position after jacobian - 7 joint positions
    dq     = zeros(n,N);    % q(:,i) collects the joint velocity for t(i) %derivative of joint position - 7 joint positions
    
    q(:,1) = [77  -17 0  43 -94 77 71]'/180*pi; % approximated home configuration - initial position for joints configuration
    q_jaco(:,1) = mask_q_DH2Jaco(q(:,1)); % what the fuck is this
    quat = zeros(4,N); % 4 quaternion variables
    
    % error variables
    error_pos = zeros(3,N); % this error is for postions
    error_quat = zeros(3,N); % this error is for quaternions - error for quaternion will be changed from 4 to 3 
    error = zeros(6,N); % this is the total error

    algorithm='inverse';

    % K initializations very important
    if strcmp(algorithm,'inverse')
        K = 10* diag([20 20 20 20 20 20]);
        fprintf('\n algoritmo con la trasposta dello jacobiano')
    else
        K = diag([90 90 90 90 90 90]);
        fprintf('\n algoritmo con la inversa dello jacobiano')
    end

    % <<
    %
    % Put here any initialization code: DH table, gains, final position,
    % cruise velocity, etc.
    
    % DH table construction from 7 joints
    a = zeros (7,1);
    alpha = [90,90,90,90,90,90,0]'/180*pi;
    d = [0.2755,0,-0.410,-0.0098,-0.3111,0,0.2638]';
    DH= [a,alpha,d,q(:,1)];
    
    % >>
    
    clc
    fprintf('----------------------');
    fprintf('\n simulation started ');
    fprintf('\n trying to connect...\n');
    [clientID, vrep ] = StartVrep(porta);
    %vrep.simxStartSimulation(clientID, vrep.simx_opmode_oneshot);
    
    handle_joint = my_get_handle_Joint(vrep,clientID);      % handle to the joints
    my_set_joint_target_position(vrep, clientID, handle_joint, q_jaco(:,1)); % first move to q0
    q_act(:,1) = my_get_joint_target_position(clientID,vrep,handle_joint,n);% get the actual joints angles from v-rep     
    % Kinova conversion -> DH
    q_act(:,1) = mask_q_Jaco2DH(q_act(:,1));
    
    % get initial position (corner) of the robot
    DH(:,4) = q(:,1);
    T = DirectKinematics(DH);
    p1  = T(1:3,4,n);
    
    % other corners
    p2 = p1 + [sideLen; 0; 0];
    p3 = p2 + [0; -sideLen; 0];
    p4 = p3 + [-sideLen; 0; 0];
    
    c_v = 0.08*ones(3,1);
    vel = zeros(1,N);
    % task 2
    rot_init = T(1:3,1:3,n);
    quat_d = zeros(4,N);
    % main simulation loop
    for i=1:N
        
        if (i*Ts)<=2.2
            [pd(:,i),dpd(:,i),~] = trapezoidal(p1,p2,c_v,2,i*Ts);
            [ang(:,i),dang(:,i),~] = trapezoidal(0,-ang_f,0.3,2,i*Ts);
            
        elseif (i*Ts)>2.2 && (i*Ts)<=4.4
            [pd(:,i),dpd(:,i),~] = trapezoidal(p2,p3,c_v,2,(i*Ts)-2.2);
            [ang(:,i),dang(:,i),~] = trapezoidal(-ang_f,0,0.3,2,(i*Ts)-2.2);
            
        elseif (i*Ts)>4.4 && (i*Ts)<=6.6
            [pd(:,i),dpd(:,i),~] = trapezoidal(p3,p4,c_v,2,(i*Ts)-4.4);
            [ang(:,i),dang(:,i),~] = trapezoidal(0,-ang_f,0.3,2,(i*Ts)-4.4);
            
        elseif (i*Ts)>6.6 && (i*Ts)<=11.6
            [pd(:,i),dpd(:,i),~] = trapezoidal(p4,p1,c_v,2,(i*Ts)-6.6);
            [ang(:,i),dang(:,i),~] = trapezoidal(-ang_f,0,0.3,2,(i*Ts)-6.6);
            
        else
            pd(:,i) = p1;dpd(:,i) = 0;
            ang(:,i)= 0;dang(:,i) = 0;
        end
        
        % direct kinematics
        DH(:,4) = q(:,i);
        T = DirectKinematics(DH);
        pc(:,i) = T(1:3,4,n);
        
        % task 2
        quat_c(:,i) = Rot2Quat(T(1:3,1:3,n));
   
        % task 3
        rot_ang = [cos(ang(:,i)) -sin(ang(:,i)) 0; sin(ang(:,i)) cos(ang(:,i)) 0; 0 0 1];
        rot_d = rot_init * rot_ang;
        quat_d(:,i) = Rot2Quat(rot_d);
        
        rot_axis = [rot_init(3,2) - rot_init(2,3);
                    rot_init(1,3)- rot_init(3,1);
                    rot_init(2,1) - rot_init(1,2)];
                
        ang_vel = dang(:,i) * rot_axis;
        v_d = [dpd(:,i);ang_vel];
        
        % for plotting
        vel(:,i) = sqrt((v_d(1)*v_d(1)) + (v_d(2)*v_d(2)));
        
        % Jacobian
        J = Jacobian(DH);
        
        % Inverse kinematics algorithm
        error_pos(:,i) = pd(:,i) - pc(:,i);
        error_quat(:,i) = QuatError(quat_d(:,i),quat_c(:,i));
        error(:,i) = [error_pos(:,i);error_quat(:,i)];
        
        if strcmp(algorithm,'transpose')
            dq(:,i) = J'*(K*error(:,i)+v_d);
        else
            dq(:,i) = pinv(J)*(K*error(:,i)+v_d);
        end
        % integration
        if i<N
            q(:,i+1) = q(:,i) + Ts*dq(:,i);
        end
        % DH -> Kinova conversion
        q_jaco(:,i) = mask_q_DH2Jaco(q(:,i));
        my_set_joint_target_position(vrep, clientID, handle_joint, q_jaco(:,i));
        q_act(:,i) = my_get_joint_target_position(clientID,vrep,handle_joint,n);% get the actual joints angles from v-rep     
        % Kinova conversion -> DH
        q_act(:,i) = mask_q_Jaco2DH(q_act(:,i));
    end
    %vrep.simxStopSimulation(clientID,vrep.simx_opmode_oneshot);
    DeleteVrep(clientID, vrep); 
    
    figure
    subplot(411)
    plot(t,q)
    ylabel('joint position')
    subplot(412)
    plot(t,dq)
    ylabel('joint velocity')
    subplot(413)
    size(t)
    size(error)
    plot(t,error(1:3,:))
    ylabel('position error ')
    subplot(414)
    plot(t,error(4:6,:))
    ylabel('orientation error')
    xlabel('time [s]')
    figure;
    DH(:,4) = q(:,1);
    DrawRobot(DH);
    DH(:,4) = q(:,N);
    DrawRobot(DH);    
    
    figure;
    plot(t,vel)
    title('trajectory velocity profile')
    xlabel('time [s]')
    figure;
    plot(pd(1,:)',pd(2,:)')
    hold on 
    plot (p1(1), p1(2),'ro')
    title('trajectory path')
    ylabel('Y [m]')
    xlabel('X [m]')
    figure;
    plot(t,ang(1,:))
    title('end effector orientation profile')
    xlabel('time [s]')
    ylabel('\theta [rad]')
end

% constructor
function [clientID, vrep ] = StartVrep(porta)

    vrep = remApi('remoteApi');   % using the prototype file (remoteApiProto.m)
    vrep.simxFinish(-1);        % just in case, close all opened connections
    clientID = vrep.simxStart('127.0.0.1',porta,true,true,5000,5);% start the simulation
    
    if (clientID>-1)
        disp('remote API server connected successfully');
    else
        disp('failed connecting to remote API server');   
        DeleteVrep(clientID, vrep); %call the destructor!
    end
    % to change the simulation step time use this command below, a custom dt in v-rep must be selected, 
    % and run matlab before v-rep otherwise it will not be changed 
    % vrep.simxSetFloatingParameter(clientID, vrep.sim_floatparam_simulation_time_step, 0.002, vrep.simx_opmode_oneshot_wait);
    vrep.simxStartSimulation(clientID, vrep.simx_opmode_oneshot);
end  

% destructor
function DeleteVrep(clientID, vrep)
    
    vrep.simxPauseSimulation(clientID,vrep.simx_opmode_oneshot_wait); % pause simulation
    %vrep.simxStopSimulation(clientID,vrep.simx_opmode_oneshot_wait); % stop simulation
    vrep.simxFinish(clientID);  % close the line if still open
    vrep.delete();              % call the destructor!
    disp('simulation ended');
    
end

function my_set_joint_target_position(vrep, clientID, handle_joint, q)
           
    [m,n] = size(q);
    for i=1:n
        for j=1:m
            err = vrep.simxSetJointPosition(clientID,handle_joint(j),q(j,i),vrep.simx_opmode_oneshot);
            if (err ~= vrep.simx_error_noerror)
                fprintf('failed to send joint angle q %d \n',j);
            end
        end
    end
    
end

function handle_joint = my_get_handle_Joint(vrep,clientID)

    [~,handle_joint(1)] = vrep.simxGetObjectHandle(clientID,'Revolute_joint_1',vrep.simx_opmode_oneshot_wait);
    [~,handle_joint(2)] = vrep.simxGetObjectHandle(clientID,'Revolute_joint_2',vrep.simx_opmode_oneshot_wait);
    [~,handle_joint(3)] = vrep.simxGetObjectHandle(clientID,'Revolute_joint_3',vrep.simx_opmode_oneshot_wait);
    [~,handle_joint(4)] = vrep.simxGetObjectHandle(clientID,'Revolute_joint_4',vrep.simx_opmode_oneshot_wait);
    [~,handle_joint(5)] = vrep.simxGetObjectHandle(clientID,'Revolute_joint_5',vrep.simx_opmode_oneshot_wait);
    [~,handle_joint(6)] = vrep.simxGetObjectHandle(clientID,'Revolute_joint_6',vrep.simx_opmode_oneshot_wait);
    [~,handle_joint(7)] = vrep.simxGetObjectHandle(clientID,'Revolute_joint_7',vrep.simx_opmode_oneshot_wait);

end

function my_set_joint_signal_position(vrep, clientID, q)
           
    [~,n] = size(q);
    
    for i=1:n
        joints_positions = vrep.simxPackFloats(q(:,i)');
        [err]=vrep.simxSetStringSignal(clientID,'jointsAngles',joints_positions,vrep.simx_opmode_oneshot_wait);

        if (err~=vrep.simx_return_ok)   
           fprintf('failed to send the string signal of iteration %d \n',i); 
        end
    end
    pause(8);% wait till the script receives all data, increase it if dt is too small or tf is too high
    
end


function angle = my_get_joint_target_position(clientID,vrep,handle_joint,n)
    
    for j=1:n
         vrep.simxGetJointPosition(clientID,handle_joint(j),vrep.simx_opmode_streaming);
    end

%     pause(0.05);

    for j=1:n          
         [err(j),angle(j)]=vrep.simxGetJointPosition(clientID,handle_joint(j),vrep.simx_opmode_buffer);
    end

    if (err(j)~=vrep.simx_return_ok)   
           fprintf(' failed to get position of joint %d \n',j); 
    end

end

